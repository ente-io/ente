package llmchat

import (
	"encoding/json"
	"strings"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
)

type clientMetadataPayload struct {
	ClientID string `json:"clientId"`
}

func MergeEncryptedData(metadata *string, encryptedData string) (*string, error) {
	if metadata == nil || strings.TrimSpace(*metadata) == "" {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "clientMetadata is required")
	}

	var payload map[string]interface{}
	if err := json.Unmarshal([]byte(*metadata), &payload); err != nil {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid clientMetadata")
	}

	payload["encryptedData"] = encryptedData
	marshaled, err := json.Marshal(payload)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to encode clientMetadata")
	}

	result := string(marshaled)
	return &result, nil
}

func ParseClientID(metadata *string) (string, error) {
	if metadata == nil || strings.TrimSpace(*metadata) == "" {
		return "", stacktrace.Propagate(ente.ErrBadRequest, "clientMetadata is required")
	}

	var payload clientMetadataPayload
	if err := json.Unmarshal([]byte(*metadata), &payload); err != nil {
		return "", stacktrace.Propagate(ente.ErrBadRequest, "invalid clientMetadata")
	}

	if strings.TrimSpace(payload.ClientID) == "" {
		return "", stacktrace.Propagate(ente.ErrBadRequest, "clientMetadata.clientId is required")
	}

	return payload.ClientID, nil
}
