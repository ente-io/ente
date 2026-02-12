package crypto

import (
	"github.com/ente-io/museum/ente"
)

// Exported constants matching libsodium
const (
	SecretBoxKeyBytes   = 32 // crypto_secretbox_KEYBYTES in libsodium
	SecretBoxNonceBytes = 24 // crypto_secretbox_NONCEBYTES in libsodium
	GenericHashBytes    = 32 // crypto_generichash_BYTES in libsodium (BLAKE2b-256)
	BoxPublicKeyBytes   = 32 // crypto_box_publickeybytes in lib-sodium
)

func Encrypt(data string, encryptionKey []byte) (ente.EncryptionResult, error) {
	return EncryptNative(data, encryptionKey)
}

func encryptWithNonce(data string, encryptionKey []byte, nonce []byte) (ente.EncryptionResult, error) {
	return encryptWithNonceNative(data, encryptionKey, nonce)
}

func Decrypt(cipher []byte, key []byte, nonce []byte) (string, error) {
	return DecryptNative(cipher, key, nonce)
}

func GetHash(data string, hashKey []byte) (string, error) {
	return GetHashNative(data, hashKey)
}

func GetEncryptedToken(token string, publicKey string) (string, error) {
	return GetEncryptedTokenNative(token, publicKey)
}
