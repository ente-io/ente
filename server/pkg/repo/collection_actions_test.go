package repo

import (
	"encoding/json"
	"testing"
)

func TestMarshalCollectionActionData(t *testing.T) {
	payload, err := marshalCollectionActionData(nil)
	if err != nil {
		t.Fatalf("unexpected error for nil data: %v", err)
	}
	if payload != nil {
		t.Fatalf("expected nil payload for nil data, got %v", payload)
	}

	data := map[string]interface{}{
		"reason": "admin_remove",
		"id":     float64(42),
	}
	payload, err = marshalCollectionActionData(data)
	if err != nil {
		t.Fatalf("unexpected error for valid data: %v", err)
	}

	payloadStr, ok := payload.(string)
	if !ok {
		t.Fatalf("expected payload to be a string, got %T", payload)
	}

	var decoded map[string]interface{}
	if err := json.Unmarshal([]byte(payloadStr), &decoded); err != nil {
		t.Fatalf("payload should be valid json, got error %v", err)
	}
	if decoded["reason"] != data["reason"] || decoded["id"] != data["id"] {
		t.Fatalf("decoded payload mismatch. expected %v, got %v", data, decoded)
	}
}
