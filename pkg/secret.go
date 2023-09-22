package pkg

import (
	"crypto/rand"
	"errors"
	"fmt"
	"log"

	"github.com/zalando/go-keyring"
)

func GetOrCreateClISecret() []byte {
	// get password
	secret, err := keyring.Get("ente-cli-cli", "ghost")
	if err != nil {
		if !errors.Is(err, keyring.ErrNotFound) {
			log.Fatal(fmt.Errorf("error getting password from keyring: %w", err))
		}
		key := make([]byte, 32)
		_, err = rand.Read(key)
		if err != nil {
			log.Fatal(fmt.Errorf("error generating key: %w", err))
		}
		secret = string(key)
		keySetErr := keyring.Set("ente-cli-cli", "ghost", string(secret))
		if keySetErr != nil {
			log.Fatal(fmt.Errorf("error setting password in keyring: %w", keySetErr))
		}

	}
	return []byte(secret)
}
