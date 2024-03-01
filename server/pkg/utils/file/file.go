package file

import (
	"fmt"
	"os"
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

func GetLockNameForObject(objectKey string) string {
	return fmt.Sprintf("Object:%s", objectKey)
}
