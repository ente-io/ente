package crypto

import (
	"encoding/base64"
	"testing"
)

const (
	password           = "test_password"
	kdfSalt            = "vd0dcYMGNLKn/gpT6uTFTw=="
	memLimit           = 64 * 1024 * 1024 // 64MB
	opsLimit           = 2
	cipherText         = "kBXQ2PuX6y/aje5r22H0AehRPh6sQ0ULoeAO"
	cipherNonce        = "v7wsI+BFZsRMIjDm3rTxPhmi/CaUdkdJ"
	expectedPlainText  = "plain_text"
	expectedDerivedKey = "vp8d8Nee0BbIML4ab8Cp34uYnyrN77cRwTl920flyT0="
)

func TestDeriveArgonKey(t *testing.T) {
	derivedKey, err := DeriveArgonKey(password, kdfSalt, memLimit, opsLimit)
	if err != nil {
		t.Fatalf("Failed to derive key: %v", err)
	}

	if base64.StdEncoding.EncodeToString(derivedKey) != expectedDerivedKey {
		t.Fatalf("Derived key does not match expected key")
	}
}

func TestDecryptChaCha20poly1305(t *testing.T) {
	derivedKey, err := DeriveArgonKey(password, kdfSalt, memLimit, opsLimit)
	if err != nil {
		t.Fatalf("Failed to derive key: %v", err)
	}

	decodedCipherText, err := base64.StdEncoding.DecodeString(cipherText)
	if err != nil {
		t.Fatalf("Failed to decode cipher text: %v", err)
	}

	decodedCipherNonce, err := base64.StdEncoding.DecodeString(cipherNonce)
	if err != nil {
		t.Fatalf("Failed to decode cipher nonce: %v", err)
	}

	decryptedText, err := decryptChaCha20poly1305(decodedCipherText, derivedKey, decodedCipherNonce)
	if err != nil {
		t.Fatalf("Failed to decrypt: %v", err)
	}
	if string(decryptedText) != expectedPlainText {
		t.Fatalf("Decrypted text : %s does not match the expected text: %s", string(decryptedText), expectedPlainText)
	}
}
