package model

import (
	"cli-go/internal/crypto"
	"cli-go/utils"
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
		CipherText: utils.EncodeBase64(cipher),
		Nonce:      utils.EncodeBase64(nonce),
	}
}

func (e *EncString) MustDecrypt(key []byte) []byte {
	plainBytes, err := crypto.DecryptChaCha20poly1305(utils.DecodeBase64(e.CipherText), key, utils.DecodeBase64(e.Nonce))
	if err != nil {
		panic(err)
	}
	return plainBytes
}
