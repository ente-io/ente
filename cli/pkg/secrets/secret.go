package secrets

import (
	"crypto/rand"
	"errors"
	"fmt"
	"github.com/ente-io/cli/utils/constants"
	"log"
	"os"

	"github.com/zalando/go-keyring"
)

func IsRunningInContainer() bool {
	if _, err := os.Stat("/.dockerenv"); err != nil {
		return false
	}
	return true
}

const (
	secretService = "ente"
	secretUser    = "ente-cli-user"
)

func GetOrCreateClISecret() []byte {
	// get password
	secret, err := keyring.Get(secretService, secretUser)

	if err != nil {
		if !errors.Is(err, keyring.ErrNotFound) {

			if secretsFile := os.Getenv("ENTE_CLI_SECRETS_PATH"); secretsFile != "" {
				return GetSecretFromSecretText(secretsFile)
			}
			if IsRunningInContainer() {
				return GetSecretFromSecretText(fmt.Sprintf("%s.secret.txt", constants.CliDataPath))
			} else {
				log.Fatal(fmt.Errorf("error getting password from keyring: %w", err))
			}
		}
		key := make([]byte, 32)
		_, err = rand.Read(key)
		if err != nil {
			log.Fatal(fmt.Errorf("error generating key: %w", err))
		}
		secret = string(key)
		keySetErr := keyring.Set(secretService, secretUser, string(secret))
		if keySetErr != nil {
			log.Fatal(fmt.Errorf("error setting password in keyring: %w", keySetErr))
		}

	}
	return []byte(secret)
}

// GetSecretFromSecretText reads the scecret from the secret text file.
// If the file does not exist, it will be created and write random 32 byte secret to it.
func GetSecretFromSecretText(secretFilePath string) []byte {

	// Check if file exists
	_, err := os.Stat(secretFilePath)
	if err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			log.Fatal(fmt.Errorf("error checking secret file: %w", err))
		}
		// File does not exist; create and write a random 32-byte secret
		key := make([]byte, 32)
		_, err := rand.Read(key)
		if err != nil {
			log.Fatal(fmt.Errorf("error generating key: %w", err))
		}
		err = os.WriteFile(secretFilePath, key, 0644)
		if err != nil {
			log.Fatal(fmt.Errorf("error writing to secret file: %w", err))
		}
		return key
	}
	// File exists; read the secret
	secret, err := os.ReadFile(secretFilePath)
	if err != nil {
		log.Fatal(fmt.Errorf("error reading from secret file: %w", err))
	}
	return secret
}
