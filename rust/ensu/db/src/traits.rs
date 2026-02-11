use std::{
    fs,
    path::{Path, PathBuf},
    time::{SystemTime, UNIX_EPOCH},
};

use uuid::Uuid;

use crate::Result;

pub trait MetaStore: Send + Sync {
    fn get(&self, key: &str) -> Result<Option<Vec<u8>>>;
    fn set(&self, key: &str, value: &[u8]) -> Result<()>;
    fn delete(&self, key: &str) -> Result<()>;
}

pub trait AttachmentStore: Send + Sync {
    fn write(&self, id: &str, data: &[u8]) -> Result<()>;
    fn read(&self, id: &str) -> Result<Vec<u8>>;
    fn delete(&self, id: &str) -> Result<()>;
    fn exists(&self, id: &str) -> Result<bool>;
}

pub trait Clock: Send + Sync {
    fn now_us(&self) -> i64;
}

pub trait UuidGen: Send + Sync {
    fn new_uuid(&self) -> Uuid;
}

#[derive(Debug, Default, Clone)]
pub struct SystemClock;

impl Clock for SystemClock {
    fn now_us(&self) -> i64 {
        let duration = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default();
        let micros = duration.as_secs() as i64 * 1_000_000;
        let sub_micros = (duration.subsec_nanos() / 1_000) as i64;
        micros + sub_micros
    }
}

#[derive(Debug, Default, Clone)]
pub struct RandomUuidGen;

impl UuidGen for RandomUuidGen {
    fn new_uuid(&self) -> Uuid {
        Uuid::new_v4()
    }
}

#[derive(Debug, Clone)]
pub struct FileMetaStore {
    root: PathBuf,
}

impl FileMetaStore {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    fn key_path(&self, key: &str) -> PathBuf {
        let encoded = ente_core::crypto::bin2base64(key.as_bytes(), true);
        self.root.join(encoded)
    }

    fn ensure_root(&self) -> Result<()> {
        fs::create_dir_all(&self.root)?;
        Ok(())
    }
}

impl MetaStore for FileMetaStore {
    fn get(&self, key: &str) -> Result<Option<Vec<u8>>> {
        let path = self.key_path(key);
        match fs::read(&path) {
            Ok(bytes) => Ok(Some(bytes)),
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(None),
            Err(err) => Err(err.into()),
        }
    }

    fn set(&self, key: &str, value: &[u8]) -> Result<()> {
        self.ensure_root()?;
        let path = self.key_path(key);
        fs::write(path, value)?;
        Ok(())
    }

    fn delete(&self, key: &str) -> Result<()> {
        let path = self.key_path(key);
        match fs::remove_file(path) {
            Ok(()) => Ok(()),
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(err) => Err(err.into()),
        }
    }
}

#[derive(Debug, Clone)]
pub struct FsAttachmentStore {
    root: PathBuf,
}

impl FsAttachmentStore {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn size(&self, id: &str) -> Result<u64> {
        let path = self.attachment_path(id);
        Ok(fs::metadata(path)?.len())
    }

    pub fn clear_all(&self) -> Result<()> {
        if self.root.exists() {
            fs::remove_dir_all(&self.root)?;
        }
        fs::create_dir_all(&self.root)?;
        Ok(())
    }

    fn attachment_path(&self, id: &str) -> PathBuf {
        self.root.join(id)
    }

    fn ensure_root(&self) -> Result<()> {
        fs::create_dir_all(&self.root)?;
        Ok(())
    }
}

impl AttachmentStore for FsAttachmentStore {
    fn write(&self, id: &str, data: &[u8]) -> Result<()> {
        self.ensure_root()?;
        let path = self.attachment_path(id);
        fs::write(path, data)?;
        Ok(())
    }

    fn read(&self, id: &str) -> Result<Vec<u8>> {
        let path = self.attachment_path(id);
        Ok(fs::read(path)?)
    }

    fn delete(&self, id: &str) -> Result<()> {
        let path = self.attachment_path(id);
        match fs::remove_file(path) {
            Ok(()) => Ok(()),
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(err) => Err(err.into()),
        }
    }

    fn exists(&self, id: &str) -> Result<bool> {
        let path = self.attachment_path(id);
        Ok(path.exists())
    }
}

pub fn ensure_directory(path: impl AsRef<Path>) -> Result<()> {
    fs::create_dir_all(path)?;
    Ok(())
}
