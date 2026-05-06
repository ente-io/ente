use std::error::Error;
use std::fmt::{Display, Formatter};
use std::fs::{File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

/// Shared random-access source abstraction for HEIF payload ingestion.
pub trait RandomAccessSource {
    /// Total source length in bytes.
    fn len(&self) -> u64;

    /// Whether the source has zero bytes.
    fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Read an exact byte range into `output`.
    fn read_exact_at(&mut self, offset: u64, output: &mut [u8]) -> Result<(), SourceReadError>;

    /// Read an exact byte range and return owned bytes.
    fn read_range(&mut self, offset: u64, len: usize) -> Result<Vec<u8>, SourceReadError> {
        let mut output = vec![0_u8; len];
        self.read_exact_at(offset, &mut output)?;
        Ok(output)
    }
}

impl<T: RandomAccessSource + ?Sized> RandomAccessSource for &mut T {
    fn len(&self) -> u64 {
        (**self).len()
    }

    fn read_exact_at(&mut self, offset: u64, output: &mut [u8]) -> Result<(), SourceReadError> {
        (**self).read_exact_at(offset, output)
    }
}

#[derive(Debug)]
pub enum SourceReadError {
    RangeOverflow {
        offset: u64,
        requested: usize,
    },
    OutOfBounds {
        offset: u64,
        requested: usize,
        source_len: u64,
    },
    Io {
        operation: &'static str,
        offset: u64,
        requested: usize,
        source: std::io::Error,
    },
    SpoolLimitExceeded {
        attempted: u64,
        max_allowed: u64,
    },
    SpoolDirectoryCreateFailed {
        directory: PathBuf,
        source: std::io::Error,
    },
    SpoolDirectoryOpenFailed {
        directory: PathBuf,
        source: std::io::Error,
    },
}

impl Display for SourceReadError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            SourceReadError::RangeOverflow { offset, requested } => {
                write!(
                    f,
                    "source range overflow while reading {requested} bytes at offset {offset}"
                )
            }
            SourceReadError::OutOfBounds {
                offset,
                requested,
                source_len,
            } => write!(
                f,
                "source read out of bounds: requested {requested} bytes at offset {offset}, source length is {source_len}"
            ),
            SourceReadError::Io {
                operation,
                offset,
                requested,
                source,
            } => write!(
                f,
                "source {operation} failed for {requested} bytes at offset {offset}: {source}"
            ),
            SourceReadError::SpoolLimitExceeded {
                attempted,
                max_allowed,
            } => write!(
                f,
                "temp spool limit exceeded while ingesting non-seek input: attempted {attempted} bytes, max allowed is {max_allowed}"
            ),
            SourceReadError::SpoolDirectoryCreateFailed { directory, source } => write!(
                f,
                "failed to create configured temp spool directory {}: {source}",
                directory.display()
            ),
            SourceReadError::SpoolDirectoryOpenFailed { directory, source } => write!(
                f,
                "failed to open temp spool file in configured directory {}: {source}",
                directory.display()
            ),
        }
    }
}

impl Error for SourceReadError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            SourceReadError::Io { source, .. } => Some(source),
            SourceReadError::SpoolDirectoryCreateFailed { source, .. } => Some(source),
            SourceReadError::SpoolDirectoryOpenFailed { source, .. } => Some(source),
            _ => None,
        }
    }
}

/// Limits applied while spooling non-seek inputs into a temporary file.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct TempFileSpoolOptions {
    /// Optional upper bound for total spooled bytes.
    pub max_spool_bytes: Option<u64>,
    /// Optional directory used to create temporary spool files.
    pub spool_directory: Option<PathBuf>,
}

fn checked_range_end(offset: u64, requested: usize) -> Result<u64, SourceReadError> {
    let requested_u64 = u64::try_from(requested)
        .map_err(|_| SourceReadError::RangeOverflow { offset, requested })?;
    offset
        .checked_add(requested_u64)
        .ok_or(SourceReadError::RangeOverflow { offset, requested })
}

fn validate_range(offset: u64, requested: usize, source_len: u64) -> Result<(), SourceReadError> {
    let end = checked_range_end(offset, requested)?;
    if end > source_len {
        return Err(SourceReadError::OutOfBounds {
            offset,
            requested,
            source_len,
        });
    }
    Ok(())
}

/// In-memory borrowed source implementation.
#[derive(Clone, Copy, Debug)]
pub struct SliceSource<'a> {
    data: &'a [u8],
}

impl<'a> SliceSource<'a> {
    pub fn new(data: &'a [u8]) -> Self {
        Self { data }
    }
}

impl RandomAccessSource for SliceSource<'_> {
    fn len(&self) -> u64 {
        self.data.len() as u64
    }

    fn read_exact_at(&mut self, offset: u64, output: &mut [u8]) -> Result<(), SourceReadError> {
        validate_range(offset, output.len(), self.len())?;
        let start = usize::try_from(offset).map_err(|_| SourceReadError::OutOfBounds {
            offset,
            requested: output.len(),
            source_len: self.len(),
        })?;
        let end = start + output.len();
        output.copy_from_slice(&self.data[start..end]);
        Ok(())
    }
}

/// Generic seek-backed source implementation.
#[derive(Debug)]
pub struct SeekableSource<R: Read + Seek> {
    reader: R,
    len: u64,
}

impl<R: Read + Seek> SeekableSource<R> {
    pub fn new(mut reader: R) -> Result<Self, SourceReadError> {
        let len = reader
            .seek(SeekFrom::End(0))
            .map_err(|source| SourceReadError::Io {
                operation: "seek-end",
                offset: 0,
                requested: 0,
                source,
            })?;
        reader
            .seek(SeekFrom::Start(0))
            .map_err(|source| SourceReadError::Io {
                operation: "seek-start",
                offset: 0,
                requested: 0,
                source,
            })?;
        Ok(Self { reader, len })
    }
}

impl<R: Read + Seek> RandomAccessSource for SeekableSource<R> {
    fn len(&self) -> u64 {
        self.len
    }

    fn read_exact_at(&mut self, offset: u64, output: &mut [u8]) -> Result<(), SourceReadError> {
        validate_range(offset, output.len(), self.len)?;
        self.reader
            .seek(SeekFrom::Start(offset))
            .map_err(|source| SourceReadError::Io {
                operation: "seek-read",
                offset,
                requested: output.len(),
                source,
            })?;
        self.reader
            .read_exact(output)
            .map_err(|source| SourceReadError::Io {
                operation: "read-exact",
                offset,
                requested: output.len(),
                source,
            })?;
        Ok(())
    }
}

pub type FileSource = SeekableSource<File>;

impl FileSource {
    pub fn open(path: &Path) -> Result<Self, SourceReadError> {
        let file = File::open(path).map_err(|source| SourceReadError::Io {
            operation: "file-open",
            offset: 0,
            requested: 0,
            source,
        })?;
        Self::new(file)
    }
}

const TEMP_SPOOL_PREFIX: &str = "ente_heic-spool";
static TEMP_SPOOL_COUNTER: AtomicU64 = AtomicU64::new(0);

fn next_temp_spool_path(directory: &Path) -> PathBuf {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .ok()
        .map_or(0, |duration| duration.as_nanos());
    let counter = TEMP_SPOOL_COUNTER.fetch_add(1, Ordering::Relaxed);
    directory.join(format!(
        "{TEMP_SPOOL_PREFIX}-{}-{nanos}-{counter}.bin",
        std::process::id()
    ))
}

fn create_temp_spool_file(
    options: &TempFileSpoolOptions,
) -> Result<(PathBuf, File), SourceReadError> {
    let spool_directory = options
        .spool_directory
        .clone()
        .unwrap_or_else(std::env::temp_dir);
    let configured_directory = options.spool_directory.is_some();
    if configured_directory {
        std::fs::create_dir_all(&spool_directory).map_err(|source| {
            SourceReadError::SpoolDirectoryCreateFailed {
                directory: spool_directory.clone(),
                source,
            }
        })?;
    }

    let mut last_already_exists: Option<std::io::Error> = None;
    for _ in 0..32 {
        let path = next_temp_spool_path(&spool_directory);
        match OpenOptions::new()
            .read(true)
            .write(true)
            .create_new(true)
            .open(&path)
        {
            Ok(file) => return Ok((path, file)),
            Err(source) if source.kind() == std::io::ErrorKind::AlreadyExists => {
                last_already_exists = Some(source);
            }
            Err(source) => {
                return Err(if configured_directory {
                    SourceReadError::SpoolDirectoryOpenFailed {
                        directory: spool_directory.clone(),
                        source,
                    }
                } else {
                    SourceReadError::Io {
                        operation: "temp-spool-open",
                        offset: 0,
                        requested: 0,
                        source,
                    }
                });
            }
        }
    }

    let source = last_already_exists.unwrap_or_else(|| {
        std::io::Error::new(
            std::io::ErrorKind::AlreadyExists,
            "failed to create unique temp spool path",
        )
    });
    Err(if configured_directory {
        SourceReadError::SpoolDirectoryOpenFailed {
            directory: spool_directory,
            source,
        }
    } else {
        SourceReadError::Io {
            operation: "temp-spool-open",
            offset: 0,
            requested: 0,
            source,
        }
    })
}

/// Random-access source backed by a temporary file that is deleted on drop.
#[derive(Debug)]
pub struct TempFileSpoolSource {
    path: PathBuf,
    source: Option<FileSource>,
}

impl TempFileSpoolSource {
    /// Spool all bytes from a non-seek `Read` into one temp file and reopen it
    /// as a seek-backed random-access source.
    pub fn from_reader<R: Read>(input_reader: R) -> Result<Self, SourceReadError> {
        Self::from_reader_with_options(input_reader, TempFileSpoolOptions::default())
    }

    /// Spool all bytes from a non-seek `Read` into one temp file and reopen it
    /// as a seek-backed random-access source while enforcing configured limits.
    pub fn from_reader_with_options<R: Read>(
        mut input_reader: R,
        options: TempFileSpoolOptions,
    ) -> Result<Self, SourceReadError> {
        let (path, mut spool_file) = create_temp_spool_file(&options)?;
        let spool_result = (|| {
            let mut bytes_written = 0_u64;
            let mut buffer = [0_u8; 64 * 1024];
            loop {
                let bytes_read =
                    input_reader
                        .read(&mut buffer)
                        .map_err(|source| SourceReadError::Io {
                            operation: "temp-spool-read",
                            offset: bytes_written,
                            requested: buffer.len(),
                            source,
                        })?;
                if bytes_read == 0 {
                    break;
                }
                let attempted = bytes_written.checked_add(bytes_read as u64).ok_or(
                    SourceReadError::RangeOverflow {
                        offset: bytes_written,
                        requested: bytes_read,
                    },
                )?;
                if let Some(max_allowed) = options.max_spool_bytes {
                    if attempted > max_allowed {
                        return Err(SourceReadError::SpoolLimitExceeded {
                            attempted,
                            max_allowed,
                        });
                    }
                }
                spool_file
                    .write_all(&buffer[..bytes_read])
                    .map_err(|source| SourceReadError::Io {
                        operation: "temp-spool-write",
                        offset: bytes_written,
                        requested: bytes_read,
                        source,
                    })?;
                bytes_written = attempted;
            }

            spool_file.flush().map_err(|source| SourceReadError::Io {
                operation: "temp-spool-flush",
                offset: bytes_written,
                requested: 0,
                source,
            })?;
            drop(spool_file);
            FileSource::open(&path)
        })();

        match spool_result {
            Ok(source) => Ok(Self {
                path,
                source: Some(source),
            }),
            Err(err) => {
                let _ = std::fs::remove_file(&path);
                Err(err)
            }
        }
    }

    fn source_ref(&self) -> &FileSource {
        self.source
            .as_ref()
            .expect("temp spool source should remain present while in use")
    }

    fn source_mut(&mut self) -> &mut FileSource {
        self.source
            .as_mut()
            .expect("temp spool source should remain present while in use")
    }
}

impl RandomAccessSource for TempFileSpoolSource {
    fn len(&self) -> u64 {
        self.source_ref().len()
    }

    fn read_exact_at(&mut self, offset: u64, output: &mut [u8]) -> Result<(), SourceReadError> {
        self.source_mut().read_exact_at(offset, output)
    }
}

impl Drop for TempFileSpoolSource {
    fn drop(&mut self) {
        // Close file handle before removing the spool path.
        let _ = self.source.take();
        let _ = std::fs::remove_file(&self.path);
    }
}
