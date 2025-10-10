package crypto

import (
	"encoding/base64"
	"github.com/sirupsen/logrus"

	"github.com/GoKillers/libsodium-go/cryptobox"
	generichash "github.com/GoKillers/libsodium-go/cryptogenerichash"
	cryptosecretbox "github.com/GoKillers/libsodium-go/cryptosecretbox"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
)

// Exported constants matching libsodium
const (
	SecretBoxKeyBytes   = 32 // crypto_secretbox_KEYBYTES in libsodium
	SecretBoxNonceBytes = 24 // crypto_secretbox_NONCEBYTES in libsodium
	GenericHashBytes    = 32 // crypto_generichash_BYTES in libsodium (BLAKE2b-256)
	BoxPublicKeyBytes   = 32 // crypto_box_publickeybytes in lib-sodium
)

func Encrypt(data string, encryptionKey []byte) (ente.EncryptionResult, error) {
	if SecretBoxNonceBytes != cryptosecretbox.CryptoSecretBoxNonceBytes() {
		return ente.EncryptionResult{}, stacktrace.NewError("SecretBoxNonceBytes constant does not match the actual nonce size")
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
	nativeEnc, err := encryptWithNonceNative(data, encryptionKey, nonce)
	if err != nil {
		logrus.WithField("op", "crypto_compare").WithError(err).Error("native encryption failed")
		return ente.EncryptionResult{}, stacktrace.Propagate(err, "native encryption failed")
	}
	if nativeEnc.Cipher == nil {
		return ente.EncryptionResult{}, stacktrace.NewError("native encryption returned nil cipher")
	}
	if base64.StdEncoding.EncodeToString(nativeEnc.Cipher) != base64.StdEncoding.EncodeToString(encryptedEmailBytes) ||
		base64.StdEncoding.EncodeToString(nativeEnc.Nonce) != base64.StdEncoding.EncodeToString(nonce) {
		logrus.WithField("op", "crypto_compare").Error("encryption mismatch between libsodium and native implementation")
		return ente.EncryptionResult{}, stacktrace.NewError("encryption mismatch  nonce or cipher not same")
	}
	return nativeEnc, nil
}

func Decrypt(cipher []byte, key []byte, nonce []byte) (string, error) {
	decryptedBytes, err := cryptosecretbox.CryptoSecretBoxOpenEasy(cipher, nonce, key)
	if err != 0 {
		return "", stacktrace.NewError("email decryption failed")
	}
	result := string(decryptedBytes)
	nativeResult, nativeErr := DecryptNative(cipher, key, nonce)
	if nativeErr != nil {
		logrus.WithField("op", "crypto_compare").WithError(nativeErr).Error("native decryption failed")
		return "", stacktrace.Propagate(nativeErr, "native decryption failed")
	} else if nativeResult != result {
		logrus.WithField("op", "crypto_compare").Error("decryption mismatch between libsodium and native implementation")
		return "", stacktrace.NewError("decryption mismatch")
	}
	return nativeResult, nil
}

func GetHash(data string, hashKey []byte) (string, error) {
	if GenericHashBytes != generichash.CryptoGenericHashBytes() {
		return "", stacktrace.NewError("GenericHashBytes constant does not match the actual hash size")
	}
	dataHashBytes, err := generichash.CryptoGenericHash(GenericHashBytes, []byte(data), hashKey)
	if err != 0 {
		return "", stacktrace.NewError("email hash failed")
	}
	result := base64.StdEncoding.EncodeToString(dataHashBytes)
	nativeResult, nativeErr := GetHashNative(data, hashKey)
	if nativeErr != nil {
		logrus.WithField("op", "crypto_compare").WithError(nativeErr).Error("native hash failed")
		return "", stacktrace.Propagate(nativeErr, "native hash failed")
	} else if nativeResult != result {
		logrus.WithField("op", "crypto_compare").Error("hash mismatch between libsodium and native implementation")
		return "", stacktrace.NewError("hash mismatch")
	}
	return nativeResult, nil
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
