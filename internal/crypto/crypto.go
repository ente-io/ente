package crypto

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"io"
	"log"

	"github.com/jamesruan/sodium"
	"golang.org/x/crypto/argon2"
)

const (
	loginSubKeyLen     = 32
	loginSubKeyId      = 1
	loginSubKeyContext = "loginctx"
)

// DeriveArgonKey generates a 32-bit cryptographic key using the Argon2id algorithm.
// Parameters:
//   - password: The plaintext password to be hashed.
//   - salt: The salt as a base64 encoded string.
//   - memLimit: The memory limit in bytes.
//   - opsLimit: The number of iterations.
//
// Returns:
//   - A byte slice representing the derived key.
//   - An error object, which is nil if no error occurs.
func DeriveArgonKey(password, salt string, memLimit, opsLimit int) ([]byte, error) {
	if memLimit < 1024 || opsLimit < 1 {
		return nil, fmt.Errorf("invalid memory or operation limits")
	}

	// Decode salt from base64
	saltBytes, err := base64.StdEncoding.DecodeString(salt)
	if err != nil {
		return nil, fmt.Errorf("invalid salt: %v", err)
	}

	// Generate key using Argon2id
	// Note: We're assuming a fixed key length of 32 bytes and changing the threads
	key := argon2.IDKey([]byte(password), saltBytes, uint32(opsLimit), uint32(memLimit/1024), 1, 32)

	return key, nil
}

// decryptChaCha20poly1305 decrypts the given data using the ChaCha20-Poly1305 algorithm.
// Parameters:
//   - data: The encrypted data as a byte slice.
//   - key: The key for decryption as a byte slice.
//   - nonce: The nonce for decryption as a byte slice.
//
// Returns:
//   - A byte slice representing the decrypted data.
//   - An error object, which is nil if no error occurs.
func decryptChaCha20poly1305(data []byte, key []byte, nonce []byte) ([]byte, error) {
	reader := bytes.NewReader(data)
	header := sodium.SecretStreamXCPHeader{Bytes: nonce}
	decoder, err := sodium.MakeSecretStreamXCPDecoder(
		sodium.SecretStreamXCPKey{Bytes: key},
		reader,
		header)
	if err != nil {
		log.Println("Failed to make secret stream decoder", err)
		return nil, err
	}
	// Buffer to store the decrypted data
	decryptedData := make([]byte, len(data))
	n, err := decoder.Read(decryptedData)
	if err != nil && err != io.EOF {
		log.Println("Failed to read from decoder", err)
		return nil, err
	}
	return decryptedData[:n], nil
}

func DeriveLoginKey(keyEncKey []byte) []byte {
	mainKey := sodium.MasterKey{Bytes: keyEncKey}
	subKey := mainKey.Derive(loginSubKeyLen, loginSubKeyId, loginSubKeyContext).Bytes
	// return the first 16 bytes of the derived key
	return subKey[:16]
}
