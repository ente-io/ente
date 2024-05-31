package crypto

import (
	"bufio"
	"errors"
	"github.com/ente-io/cli/utils/encoding"
	"golang.org/x/crypto/nacl/box"
	"golang.org/x/crypto/nacl/secretbox"
	"io"
	"log"
	"os"
)

//func EncryptChaCha20poly1305LibSodium(data []byte, key []byte) ([]byte, []byte, error) {
//	var buf bytes.Buffer
//	encoder := sodium.MakeSecretStreamXCPEncoder(sodium.SecretStreamXCPKey{Bytes: key}, &buf)
//	_, err := encoder.WriteAndClose(data)
//	if err != nil {
//		log.Println("Failed to write to encoder", err)
//		return nil, nil, err
//	}
//	return buf.Bytes(), encoder.Header().Bytes, nil
//}

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
	encryptor, header, err := NewEncryptor(key)
	if err != nil {
		return nil, nil, err
	}
	encoded, err := encryptor.Push(data, TagFinal)
	if err != nil {
		return nil, nil, err
	}
	return encoded, header, nil
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
//func decryptChaCha20poly1305LibSodium(data []byte, key []byte, nonce []byte) ([]byte, error) {
//	reader := bytes.NewReader(data)
//	header := sodium.SecretStreamXCPHeader{Bytes: nonce}
//	decoder, err := sodium.MakeSecretStreamXCPDecoder(
//		sodium.SecretStreamXCPKey{Bytes: key},
//		reader,
//		header)
//	if err != nil {
//		log.Println("Failed to make secret stream decoder", err)
//		return nil, err
//	}
//	// Buffer to store the decrypted data
//	decryptedData := make([]byte, len(data))
//	n, err := decoder.Read(decryptedData)
//	if err != nil && err != io.EOF {
//		log.Println("Failed to read from decoder", err)
//		return nil, err
//	}
//	return decryptedData[:n], nil
//}

func decryptChaCha20poly1305(data []byte, key []byte, nonce []byte) ([]byte, error) {
	decryptor, err := NewDecryptor(key, nonce)
	if err != nil {
		return nil, err
	}
	decoded, tag, err := decryptor.Pull(data)
	if tag != TagFinal {
		return nil, errors.New("invalid tag")
	}
	if err != nil {
		return nil, err
	}
	return decoded, nil
}

// decryptChaCha20poly1305V2 is used only to decrypt Ente Auth data. Ente Auth use new version of LibSodium.
// In that version, the final tag value is 0x0 instead of TagFinal.
func decryptChaCha20poly1305V2(data []byte, key []byte, nonce []byte) ([]byte, error) {
	decryptor, err := NewDecryptor(key, nonce)
	if err != nil {
		return nil, err
	}
	decoded, tag, err := decryptor.Pull(data)
	if tag != TagFinal && tag != TagMessage {
		return nil, errors.New("invalid tag")
	}
	if err != nil {
		return nil, err
	}
	return decoded, nil
}

//func SecretBoxOpenLibSodium(c []byte, n []byte, k []byte) ([]byte, error) {
//	var cp sodium.Bytes = c
//	res, err := cp.SecretBoxOpen(sodium.SecretBoxNonce{Bytes: n}, sodium.SecretBoxKey{Bytes: k})
//	return res, err
//}

func SecretBoxOpenBase64(cipher string, nonce string, k []byte) ([]byte, error) {
	return SecretBoxOpen(encoding.DecodeBase64(cipher), encoding.DecodeBase64(nonce), k)
}

func SecretBoxOpen(c []byte, n []byte, k []byte) ([]byte, error) {
	// Check for valid lengths of nonce and key
	if len(n) != 24 || len(k) != 32 {
		return nil, ErrOpenBox
	}

	var nonce [24]byte
	var key [32]byte
	copy(nonce[:], n)
	copy(key[:], k)

	// Decrypt the message using Go's nacl/secretbox
	decrypted, ok := secretbox.Open(nil, c, &nonce, &key)
	if !ok {
		return nil, ErrOpenBox
	}

	return decrypted, nil
}

//func SealedBoxOpenLib(cipherText []byte, publicKey, masterSecret []byte) ([]byte, error) {
//	var cp sodium.Bytes = cipherText
//	om, err := cp.SealedBoxOpen(sodium.BoxKP{
//		PublicKey: sodium.BoxPublicKey{Bytes: publicKey},
//		SecretKey: sodium.BoxSecretKey{Bytes: masterSecret},
//	})
//	if err != nil {
//		return nil, fmt.Errorf("failed to open sealed box: %v", err)
//	}
//	return om, nil
//}

func SealedBoxOpen(cipherText, publicKey, masterSecret []byte) ([]byte, error) {
	if len(cipherText) < BoxSealBytes {
		return nil, ErrOpenBox
	}

	// Extract ephemeral public key from the ciphertext
	var ephemeralPublicKey [32]byte
	copy(ephemeralPublicKey[:], publicKey[:32])

	// Extract ephemeral public key from the ciphertext
	var masterKey [32]byte
	copy(masterKey[:], masterSecret[:32])

	// Decrypt the message using nacl/box
	decrypted, ok := box.OpenAnonymous(nil, cipherText, &ephemeralPublicKey, &masterKey)
	if !ok {
		return nil, ErrOpenBox
	}

	return decrypted, nil
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

	decryptor, err := NewDecryptor(key, nonce)
	if err != nil {
		return err
	}

	buf := make([]byte, decryptionBufferSize+XChaCha20Poly1305IetfABYTES)
	for {
		readCount, err := reader.Read(buf)
		if err != nil && err != io.EOF {
			log.Println("Failed to read from input file", err)
			return err
		}
		if readCount == 0 {
			break
		}
		n, tag, errErr := decryptor.Pull(buf[:readCount])
		if errErr != nil && errErr != io.EOF {
			log.Println("Failed to read from decoder", errErr)
			return errErr
		}

		if _, err := writer.Write(n); err != nil {
			log.Println("Failed to write to output file", err)
			return err
		}
		if errErr == io.EOF {
			break
		}
		if tag == TagFinal {
			break
		}
	}
	if err := writer.Flush(); err != nil {
		log.Println("Failed to flush writer", err)
		return err
	}
	return nil
}

//func DecryptFileLib(encryptedFilePath string, decryptedFilePath string, key, nonce []byte) error {
//	inputFile, err := os.Open(encryptedFilePath)
//	if err != nil {
//		return err
//	}
//	defer inputFile.Close()
//
//	outputFile, err := os.Create(decryptedFilePath)
//	if err != nil {
//		return err
//	}
//	defer outputFile.Close()
//
//	reader := bufio.NewReader(inputFile)
//	writer := bufio.NewWriter(outputFile)
//
//	header := sodium.SecretStreamXCPHeader{Bytes: nonce}
//	decoder, err := sodium.MakeSecretStreamXCPDecoder(
//		sodium.SecretStreamXCPKey{Bytes: key},
//		reader,
//		header)
//	if err != nil {
//		log.Println("Failed to make secret stream decoder", err)
//		return err
//	}
//
//	buf := make([]byte, decryptionBufferSize)
//	for {
//		n, errErr := decoder.Read(buf)
//		if errErr != nil && errErr != io.EOF {
//			log.Println("Failed to read from decoder", errErr)
//			return errErr
//		}
//		if n == 0 {
//			break
//		}
//		if _, err := writer.Write(buf[:n]); err != nil {
//			log.Println("Failed to write to output file", err)
//			return err
//		}
//		if errErr == io.EOF {
//			break
//		}
//	}
//	if err := writer.Flush(); err != nil {
//		log.Println("Failed to flush writer", err)
//		return err
//	}
//	return nil
//}
