package crypto

import (
	"encoding/base64"
	"fmt"
	"github.com/ente-io/stacktrace"

	"github.com/GoKillers/libsodium-go/cryptobox"
	generichash "github.com/GoKillers/libsodium-go/cryptogenerichash"
	cryptosecretbox "github.com/GoKillers/libsodium-go/cryptosecretbox"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
)

// Exported constants matching libsodium
const (
	SecretBoxKeyBytes   = 32 // crypto_secretbox_KEYBYTES in libsodium
	SecretBoxNonceBytes = 24 // crypto_secretbox_NONCEBYTES in libsodium
	GenericHashBytes    = 32 // crypto_generichash_BYTES in libsodium (BLAKE2b-256)
)

func Encrypt(data string, encryptionKey []byte) (ente.EncryptionResult, error) {
	if SecretBoxNonceBytes != cryptosecretbox.CryptoSecretBoxNonceBytes() {
		panic("SecretBoxNonceBytes constant does not match the actual nonce size")
	}
	nonce, err := auth.GenerateRandomBytes(SecretBoxNonceBytes)
	if err != nil {
		return ente.EncryptionResult{}, stacktrace.Propagate(err, "")
	}
	return encryptWithNonce(data, encryptionKey, nonce)
}

func encryptWithNonce(data string, encryptionKey []byte, nonce []byte) (ente.EncryptionResult, error) {
	encryptedEmailBytes, errCode := cryptosecretbox.CryptoSecretBoxEasy([]byte(data), nonce, encryptionKey)
	if errCode != 0 {
		return ente.EncryptionResult{}, stacktrace.NewError("encryption failed")
	}
	return ente.EncryptionResult{Cipher: encryptedEmailBytes, Nonce: nonce}, nil
}

func Decrypt(cipher []byte, key []byte, nonce []byte) (string, error) {
	decryptedBytes, err := cryptosecretbox.CryptoSecretBoxOpenEasy(cipher, nonce, key)
	if err != 0 {
		return "", stacktrace.NewError("email decryption failed")
	}
	return string(decryptedBytes), nil
}

func GetHash(data string, hashKey []byte) (string, error) {
	if GenericHashBytes != generichash.CryptoGenericHashBytes() {
		panic(fmt.Sprintf("GenericHashBytes constant %d does not match the actual hash size %d",
			GenericHashBytes, generichash.CryptoGenericHashBytes()))
	}
	dataHashBytes, err := generichash.CryptoGenericHash(GenericHashBytes, []byte(data), hashKey)
	if err != 0 {
		return "", stacktrace.NewError("email hash failed")
	}
	result := base64.StdEncoding.EncodeToString(dataHashBytes)
	nativeResult, err2 := GetHashNative(data, hashKey)
	if err2 != nil {
		return "", stacktrace.Propagate(err2, "failed to get native hash")
	}
	if result != nativeResult {
		return "", stacktrace.NewError("hash mismatch between libsodium and native implementations")
	}
	return result, nil

}

func GetEncryptedToken(token string, publicKey string) (string, error) {
	publicKeyBytes, err := base64.StdEncoding.DecodeString(publicKey)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	tokenBytes, err := base64.URLEncoding.DecodeString(token)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	encryptedTokenBytes, errCode := cryptobox.CryptoBoxSeal(tokenBytes, publicKeyBytes)
	if errCode != 0 {
		return "", stacktrace.NewError("token encryption failed")
	}
	return base64.StdEncoding.EncodeToString(encryptedTokenBytes), nil
}
