package file

import (
	"fmt"
	"os"
	"strings"
	"syscall"

	"github.com/ente-io/stacktrace"
)

func MakeDirectoryIfNotExists(path string) error {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return os.MkdirAll(path, os.ModeDir|0755)
	}
	return nil
}

func DeleteAllFilesInDirectory(path string) error {
	_, err := os.Stat(path)
	if err != nil {
		// os.Stat throwing error would mean, file path does not exist
		return nil
	}
	err = os.RemoveAll(path)
	return stacktrace.Propagate(err, "")
}

// FreeSpace returns the free space in bytes on the disk where path is mounted.
func FreeSpace(path string) (uint64, error) {
	var fs syscall.Statfs_t
	err := syscall.Statfs(path, &fs)
	if err != nil {
		return 0, err
	}
	return fs.Bfree * uint64(fs.Bsize), nil
}

// EnsureSufficientSpace Return an error if we risk running out of disk space if we try to download
// and write a file of size.
// This function keeps a buffer of 2 GB free space in its calculations.
func EnsureSufficientSpace(size int64) error {
	free, err := FreeSpace("/")
	if err != nil {
		return stacktrace.Propagate(err, "Failed to fetch free space")
	}

	gb := uint64(1024) * 1024 * 1024
	need := uint64(size) + (2 * gb)
	if free < need {
		return fmt.Errorf("insufficient space on disk (need %d bytes, free %d bytes)", size, free)
	}

	return nil
}

// CreateTemporaryFile Create a file, and return both the path to the
// file, and the handle to the file.
// The caller must Close() the returned file if it is not nil.
func CreateTemporaryFile(tempStorage string, tempFileName string) (string, *os.File, error) {
	fileName := strings.ReplaceAll(tempFileName, "/", "_")
	filePath := tempStorage + "/" + fileName
	f, err := os.Create(filePath)
	if err != nil {
		return "", nil, stacktrace.Propagate(err, "Could not create temporary file at '%s' to download object", filePath)
	}
	return filePath, f, nil
}

func GetLockNameForObject(objectKey string) string {
	return fmt.Sprintf("Object:%s", objectKey)
}
