package crypto

import (
	"bufio"
	"bytes"
	"cli-go/utils/encoding"
	"encoding/base64"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/jamesruan/sodium"
	"golang.org/x/crypto/argon2"
)

const (
	loginSubKeyLen     = 32
	loginSubKeyId      = 1
	loginSubKeyContext = "loginctx"

	decryptionBufferSize = 4 * 1024 * 1024
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

// DecryptChaCha20poly1305 decrypts the given data using the ChaCha20-Poly1305 algorithm.
// Parameters:
//   - data: The encrypted data as a byte slice.
//   - key: The key for decryption as a byte slice.
//   - nonce: The nonce for decryption as a byte slice.
//
// Returns:
//   - A byte slice representing the decrypted data.
//   - An error object, which is nil if no error occurs.
func DecryptChaCha20poly1305(data []byte, key []byte, nonce []byte) ([]byte, error) {
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

func DecryptChaChaBase64(data string, key []byte, nonce string) (string, []byte, error) {
	// Decode data from base64
	dataBytes, err := base64.StdEncoding.DecodeString(data)
	if err != nil {
		return "", nil, fmt.Errorf("invalid data: %v", err)
	}
	// Decode nonce from base64
	nonceBytes, err := base64.StdEncoding.DecodeString(nonce)
	if err != nil {
		return "", nil, fmt.Errorf("invalid nonce: %v", err)
	}
	// Decrypt data
	decryptedData, err := DecryptChaCha20poly1305(dataBytes, key, nonceBytes)
	if err != nil {
		return "", nil, fmt.Errorf("failed to decrypt data: %v", err)
	}
	return base64.StdEncoding.EncodeToString(decryptedData), decryptedData, nil
}

// EncryptChaCha20poly1305 encrypts the given data using the ChaCha20-Poly1305 algorithm.
// Parameters:
//   - data: The plaintext data as a byte slice.
//   - key: The key for encryption as a byte slice.
//
// Returns:
//   - A byte slice representing the encrypted data.
//   - A byte slice representing the header of the encrypted data.
//   - An error object, which is nil if no error occurs.
func EncryptChaCha20poly1305(data []byte, key []byte) ([]byte, []byte, error) {
	var buf bytes.Buffer
	encoder := sodium.MakeSecretStreamXCPEncoder(sodium.SecretStreamXCPKey{Bytes: key}, &buf)
	_, err := encoder.WriteAndClose(data)
	if err != nil {
		log.Println("Failed to write to encoder", err)
		return nil, nil, err
	}
	return buf.Bytes(), encoder.Header().Bytes, nil
}

// DeriveLoginKey derives a login key from the given key encryption key.
// This loginKey act as user provided password during SRP authentication.
// Parameters: keyEncKey: This is the keyEncryptionKey that is derived from the user's password.
func DeriveLoginKey(keyEncKey []byte) []byte {
	mainKey := sodium.MasterKey{Bytes: keyEncKey}
	subKey := mainKey.Derive(loginSubKeyLen, loginSubKeyId, loginSubKeyContext).Bytes
	// return the first 16 bytes of the derived key
	return subKey[:16]
}

func SecretBoxOpen(c []byte, n []byte, k []byte) ([]byte, error) {
	var cp sodium.Bytes = c
	return cp.SecretBoxOpen(sodium.SecretBoxNonce{Bytes: n}, sodium.SecretBoxKey{Bytes: k})
}

func SecretBoxOpenBase64(cipher string, nonce string, k []byte) ([]byte, error) {
	var cp sodium.Bytes = encoding.DecodeBase64(cipher)
	out, err := cp.SecretBoxOpen(sodium.SecretBoxNonce{Bytes: encoding.DecodeBase64(nonce)}, sodium.SecretBoxKey{Bytes: k})
	if err != nil {
		return nil, err
	}
	return out, nil
}

func SealedBoxOpen(cipherText []byte, publicKey, masterSecret []byte) ([]byte, error) {
	var cp sodium.Bytes = cipherText
	om, err := cp.SealedBoxOpen(sodium.BoxKP{
		PublicKey: sodium.BoxPublicKey{Bytes: publicKey},
		SecretKey: sodium.BoxSecretKey{Bytes: masterSecret},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to open sealed box: %v", err)
	}
	return om, nil
}

func DecryptFile(encryptedFilePath string, decryptedFilePath string, key, nonce []byte) error {
	inputFile, err := os.Open(encryptedFilePath)
	if err != nil {
		return err
	}
	defer inputFile.Close()

	outputFile, err := os.Create(decryptedFilePath)
	if err != nil {
		return err
	}
	defer outputFile.Close()

	reader := bufio.NewReader(inputFile)
	writer := bufio.NewWriter(outputFile)

	header := sodium.SecretStreamXCPHeader{Bytes: nonce}
	decoder, err := sodium.MakeSecretStreamXCPDecoder(
		sodium.SecretStreamXCPKey{Bytes: key},
		reader,
		header)
	if err != nil {
		log.Println("Failed to make secret stream decoder", err)
		return err
	}

	buf := make([]byte, decryptionBufferSize)
	for {
		n, errErr := decoder.Read(buf)
		if errErr != nil && errErr != io.EOF {
			log.Println("Failed to read from decoder", errErr)
			return errErr
		}
		if n == 0 {
			break
		}
		if _, err := writer.Write(buf[:n]); err != nil {
			log.Println("Failed to write to output file", err)
			return err
		}
		if errErr == io.EOF {
			break
		}
	}
	if err := writer.Flush(); err != nil {
		log.Println("Failed to flush writer", err)
		return err
	}
	return nil
}
