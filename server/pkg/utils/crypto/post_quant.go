package crypto

import (
	"encoding/base64"
	"fmt"
)

func ExtractPreQuantKey(encodedKey string) (string, error) {
	key, err := base64.StdEncoding.DecodeString(encodedKey)
	if err != nil {
		return "", fmt.Errorf("failed to decode base64 key: %w", err)
	}
	if len(key) < 32 {
		return "", fmt.Errorf("decoded key too short: got %d bytes, need at least 32", len(key))
	}
	return base64.StdEncoding.EncodeToString(key[:32]), nil
}
