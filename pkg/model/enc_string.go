package model

import (
	"cli-go/internal/crypto"
	"cli-go/utils/encoding"
	"log"
)

type EncString struct {
	CipherText string `json:"cipherText"`
	Nonce      string `json:"nonce"`
}

func MakeEncString(plainTextBytes []byte, key []byte) *EncString {
	cipher, nonce, err := crypto.EncryptChaCha20poly1305(plainTextBytes, key)
	if err != nil {
		log.Fatalf("failed to encrypt %s", err)
	}
	return &EncString{
		CipherText: encoding.EncodeBase64(cipher),
		Nonce:      encoding.EncodeBase64(nonce),
	}
}

func (e *EncString) MustDecrypt(key []byte) []byte {
	plainBytes, err := crypto.DecryptChaCha20poly1305(encoding.DecodeBase64(e.CipherText), key, encoding.DecodeBase64(e.Nonce))
	if err != nil {
		panic(err)
	}
	return plainBytes
}
