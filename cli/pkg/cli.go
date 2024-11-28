package pkg

import (
	"fmt"
	"github.com/ente-io/cli/internal/api"
	"github.com/ente-io/cli/pkg/secrets"
	bolt "go.etcd.io/bbolt"
	"os"
	"path/filepath"
)

type ClICtrl struct {
	Client     *api.Client
	DB         *bolt.DB
	KeyHolder  *secrets.KeyHolder
	tempFolder string
}

func (c *ClICtrl) Init() error {
	tempPath := filepath.Join(GetCLITempPath(), "ente-download")
	// create temp folder if not exists
	if _, err := os.Stat(tempPath); os.IsNotExist(err) {
		err = os.Mkdir(tempPath, 0755)
		if err != nil {
			return err
		}
	}
	c.tempFolder = tempPath
	return c.DB.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(AccBucket))
		if err != nil {
			return fmt.Errorf("create bucket: %s", err)
		}
		return nil
	})
}

func GetCLITempPath() (string) {
	if os.Getenv("ENTE_CLI_TMP_PATH") != "" {
		return os.Getenv("ENTE_CLI_TMP_PATH")
	}
	return os.TempDir()
}

// Configure Museum Server Directory to find proper <environment.yaml> file.
// Made for and used in command `ente account public-albums-url [url]`
func ConfigureServerDir() (string) {
  serverEnv := os.Getenv("ENTE_SERVER_DIR")
  if serverEnv != "" {
    fmt.Errorf(`ENTE_SERVER_DIR environment is not set, please setup it with\n 
      export ENTE_SERVER_DIR=/path/to/ente/
      `)
  }

  configDir := filepath.Join(serverEnv, "server", "configurations")
  return configDir
}
