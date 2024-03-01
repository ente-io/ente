package crypto

import (
	"github.com/ente-io/stacktrace"

	"encoding/base64"

	"github.com/GoKillers/libsodium-go/cryptobox"
	generichash "github.com/GoKillers/libsodium-go/cryptogenerichash"
	cryptosecretbox "github.com/GoKillers/libsodium-go/cryptosecretbox"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
)

func Encrypt(data string, encryptionKey []byte) (ente.EncryptionResult, error) {
	nonce, err := auth.GenerateRandomBytes(cryptosecretbox.CryptoSecretBoxNonceBytes())
	if err != nil {
		return ente.EncryptionResult{}, stacktrace.Propagate(err, "")
	}
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
	dataHashBytes, err := generichash.CryptoGenericHash(generichash.CryptoGenericHashBytes(), []byte(data), hashKey)
	if err != 0 {
		return "", stacktrace.NewError("email hash failed")
	}
	return base64.StdEncoding.EncodeToString(dataHashBytes), nil
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
