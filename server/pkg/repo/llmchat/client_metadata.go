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
