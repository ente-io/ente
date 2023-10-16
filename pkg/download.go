package pkg

import (
	"archive/zip"
	"cli-go/internal/crypto"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func (c *ClICtrl) downloadAndDecrypt(
	ctx context.Context,
	file model.RemoteFile,
	deviceKey []byte,
) (*string, error) {
	dir, err := os.MkdirTemp("", "ente-cli-download")
	if err != nil {
		return nil, err
	}
	downloadPath := fmt.Sprintf("%s/%d", dir, file.ID)
	log.Printf("Downloading file %d to %s", file.ID, downloadPath)
	err = c.Client.DownloadFile(ctx, file.ID, downloadPath)
	if err != nil {
		return nil, fmt.Errorf("error downloading file %d: %w", file.ID, err)
	}
	decryptedPath := fmt.Sprintf("%s/%d.decrypted", dir, file.ID)
	err = crypto.DecryptFile(downloadPath, decryptedPath, file.Key.MustDecrypt(deviceKey), encoding.DecodeBase64(file.FileNonce))
	if err != nil {
		return nil, fmt.Errorf("error decrypting file %d: %w", file.ID, err)
	}
	return &decryptedPath, nil
}

func UnpackLive(src string) (imagePath, videoPath string, retErr error) {
	var filenames []string
	reader, err := zip.OpenReader(src)
	if err != nil {
		retErr = err
		return
	}
	defer reader.Close()

	dest := filepath.Dir(src)

	for _, file := range reader.File {
		destFilePath := filepath.Join(dest, file.Name)
		filenames = append(filenames, destFilePath)

		destDir := filepath.Dir(destFilePath)
		if err := os.MkdirAll(destDir, 0755); err != nil {
			retErr = err
			return
		}

		destFile, err := os.Create(destFilePath)
		if err != nil {
			retErr = err
			return
		}
		defer destFile.Close()

		srcFile, err := file.Open()
		if err != nil {
			retErr = err
			return
		}
		defer srcFile.Close()

		_, err = io.Copy(destFile, srcFile)
		if err != nil {
			retErr = err
			return
		}
	}
	for _, filepath := range filenames {
		if strings.Contains(strings.ToLower(filepath), "image") {
			imagePath = filepath
		} else if strings.Contains(strings.ToLower(filepath), "video") {
			videoPath = filepath
		} else {
			retErr = fmt.Errorf("unexpcted file in zip %s", filepath)
		}
	}
	return
}
