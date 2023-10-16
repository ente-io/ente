package pkg

import (
	"cli-go/internal/crypto"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"fmt"
	"log"
	"os"
)

func (c *ClICtrl) downloadAndDecrypt(
	ctx context.Context,
	file model.RemoteFile,
	deviceKey []byte,
) (*string, error) {
	dir, err := os.MkdirTemp("", "ente-cli-download/*")
	if err != nil {
		return nil, err
	}
	downloadPath := fmt.Sprintf("%s/%d", dir, file.ID)
	log.Printf("Downloading file %d to %s", file.ID, downloadPath)
	err = c.Client.DownloadFile(ctx, file.ID, downloadPath)
	if err != nil {
		return nil, err
	}
	decryptedPath := fmt.Sprintf("%s/%d.decrypted", dir, file.ID)
	err = crypto.DecryptFile(downloadPath, decryptedPath, file.Key.MustDecrypt(deviceKey), encoding.DecodeBase64(file.FileNonce))
	if err != nil {
		return nil, err
	}
	return &decryptedPath, nil
}
