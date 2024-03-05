package ente

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
)

// EncData is a struct that holds an encrypted data and related nonce.
type EncData struct {
	Data  string `json:"data"`
	Nonce string `json:"nonce"`
}

// Value implements the driver.Valuer interface, allowing EncString to be used as a SQL value.
func (e EncData) Value() (driver.Value, error) {
	return json.Marshal(e)
}

// Scan implements the sql.Scanner interface, allowing EncString to be scanned from SQL queries.
func (e *EncData) Scan(value interface{}) error {
	// Convert to bytes if necessary (depends on the driver, pq returns []byte for JSONB)
	b, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("type assertion to []byte failed")
	}
	return json.Unmarshal(b, &e)
}
