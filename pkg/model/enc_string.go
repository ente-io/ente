package model

import (
	"cli-go/internal/crypto"
	"log"
)

type EncString struct {
	CipherText string `json:"cipherText"`
	Nonce      string `json:"nonce"`
}

func MakeEncString(plainText string, key []byte) *EncString {
	cipher, nonce, err := crypto.EncryptChaCha20poly1305([]byte(plainText), key)
	if err != nil {
		log.Fatalf("failed to encrypt %s", err)
	}
	return &EncString{
		CipherText: string(cipher),
		Nonce:      string(nonce),
	}
}

func (e *EncString) MustDecrypt(key []byte) string {
	plainBytes, err := crypto.DecryptChaCha20poly1305([]byte(e.CipherText), key, []byte(e.Nonce))
	if err != nil {
		panic(err)
	}
	return string(plainBytes)
}
