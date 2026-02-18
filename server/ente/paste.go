package ente

import (
	"strings"
	"unicode"
)

type CreatePasteRequest struct {
	EncryptedData    string `json:"encryptedData" binding:"required"`
	DecryptionHeader string `json:"decryptionHeader" binding:"required"`
}

func (r *CreatePasteRequest) Validate(maxCiphertextBytes int) error {
	if strings.TrimSpace(r.EncryptedData) == "" || strings.TrimSpace(r.DecryptionHeader) == "" {
		return NewBadRequestWithMessage("invalid encrypted payload")
	}
	if len(r.EncryptedData) > maxCiphertextBytes || len(r.DecryptionHeader) > maxCiphertextBytes {
		return NewBadRequestWithMessage("encrypted payload too large")
	}
	return nil
}

type CreatePasteResponse struct {
	AccessToken string `json:"accessToken"`
	ExpiresAt   int64  `json:"expiresAt"`
}

type PasteTokenRequest struct {
	AccessToken string `json:"accessToken" binding:"required"`
}

func (r *PasteTokenRequest) Validate() error {
	token := strings.TrimSpace(r.AccessToken)
	if token == "" {
		return NewBadRequestWithMessage("access token required")
	}
	if len(token) < 6 || len(token) > 32 {
		return NewBadRequestWithMessage("invalid access token")
	}
	if !isAlphaNumeric(token) {
		return NewBadRequestWithMessage("invalid access token")
	}
	return nil
}

type PastePayload struct {
	EncryptedData    string `json:"encryptedData"`
	DecryptionHeader string `json:"decryptionHeader"`
}

func isAlphaNumeric(s string) bool {
	for _, r := range s {
		if !unicode.IsLetter(r) && !unicode.IsDigit(r) {
			return false
		}
	}
	return true
}
