package ente

import (
	"encoding/base64"
	"strings"
	"testing"
)

func newValidPasteRequest() CreatePasteRequest {
	return CreatePasteRequest{
		EncryptedData:          "encrypted-data",
		DecryptionHeader:       "decryption-header",
		EncryptedPasteKey:      "encrypted-paste-key",
		EncryptedPasteKeyNonce: "encrypted-paste-key-nonce",
		KdfNonce:               base64.StdEncoding.EncodeToString(make([]byte, pasteKdfSaltBytes)),
		KdfMemLimit:            pasteKdfMemLimitInteractive,
		KdfOpsLimit:            pasteKdfOpsLimitInteractive,
	}
}

func TestCreatePasteRequestValidate_Valid(t *testing.T) {
	req := newValidPasteRequest()
	if err := req.Validate(1024); err != nil {
		t.Fatalf("expected valid request, got error: %v", err)
	}
}

func TestCreatePasteRequestValidate_RejectsOversizedKdfNonce(t *testing.T) {
	req := newValidPasteRequest()
	req.KdfNonce = strings.Repeat("a", pasteKdfNonceMaxLength+1)

	if err := req.Validate(1024); err == nil {
		t.Fatal("expected oversized kdf nonce to be rejected")
	}
}

func TestCreatePasteRequestValidate_RejectsInvalidKdfNonceEncoding(t *testing.T) {
	req := newValidPasteRequest()
	req.KdfNonce = "not-base64@@@"

	if err := req.Validate(1024); err == nil {
		t.Fatal("expected invalid kdf nonce encoding to be rejected")
	}
}

func TestCreatePasteRequestValidate_RejectsUnexpectedKdfNonceLength(t *testing.T) {
	req := newValidPasteRequest()
	req.KdfNonce = base64.StdEncoding.EncodeToString(make([]byte, 8))

	if err := req.Validate(1024); err == nil {
		t.Fatal("expected invalid kdf nonce length to be rejected")
	}
}

func TestCreatePasteRequestValidate_RejectsInvalidKdfCostParams(t *testing.T) {
	req := newValidPasteRequest()
	req.KdfMemLimit = pasteKdfMemLimitInteractive * 2
	req.KdfOpsLimit = pasteKdfOpsLimitInteractive * 2

	if err := req.Validate(1024); err == nil {
		t.Fatal("expected invalid kdf cost params to be rejected")
	}
}
