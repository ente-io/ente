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

func MakeEncString(plainText string, key []byte) *EncString {
	cipher, nonce, err := crypto.EncryptChaCha20poly1305([]byte(plainText), key)
	if err != nil {
		log.Fatalf("failed to encrypt %s", err)
	}
	return &EncString{
		CipherText: utils.BytesToBase64(cipher),
		Nonce:      utils.BytesToBase64(nonce),
	}
}

func (e *EncString) MustDecrypt(key []byte) string {
	plainBytes, err := crypto.DecryptChaCha20poly1305(utils.Base64DecodeString(e.CipherText), key, utils.Base64DecodeString(e.Nonce))
	if err != nil {
		panic(err)
	}
	return utils.BytesToBase64(plainBytes)
}
