package model

import (
	"crypto/rand"
	"testing"
)

func TestEncString(t *testing.T) {
	key := make([]byte, 32)
	_, err := rand.Read(key)
	if err != nil {
		t.Fatalf("error generating key: %v", err)
	}
	data := "dataToEncrypt"
	encData := MakeEncString(data, key)
	decryptedData := encData.MustDecrypt(key)
	if decryptedData != data {
		t.Fatalf("decrypted data is not equal to original data")
	}
}
