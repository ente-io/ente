package ente

import (
	"database/sql/driver"
	"encoding/json"
	"github.com/ente-io/stacktrace"
	"github.com/google/uuid"
)

// LocationTag represents a location tag in the system. The location information
// is stored in an encrypted as Attributes
type LocationTag struct {
	ID                 uuid.UUID            `json:"id"`
	OwnerID            int64                `json:"ownerId,omitempty"`
	EncryptedKey       string               `json:"encryptedKey" binding:"required"`
	KeyDecryptionNonce string               `json:"keyDecryptionNonce" binding:"required"`
	Attributes         LocationTagAttribute `json:"attributes" binding:"required"`
	IsDeleted          bool                 `json:"isDeleted"`
	Provider           string               `json:"provider,omitempty"`
	CreatedAt          int64                `json:"createdAt,omitempty"` // utc epoch microseconds
	UpdatedAt          int64                `json:"updatedAt,omitempty"` // utc epoch microseconds
}

// LocationTagAttribute holds encrypted data about user's location tag.
type LocationTagAttribute struct {
	Version         int    `json:"version,omitempty" binding:"required"`
	EncryptedData   string `json:"encryptedData,omitempty" binding:"required"`
	DecryptionNonce string `json:"decryptionNonce,omitempty" binding:"required"`
}

// Value implements the driver.Valuer interface. This method
// simply returns the JSON-encoded representation of the struct.
func (la LocationTagAttribute) Value() (driver.Value, error) {
	return json.Marshal(la)
}

// Scan implements the sql.Scanner interface. This method
// simply decodes a JSON-encoded value into the struct fields.
func (la *LocationTagAttribute) Scan(value interface{}) error {
	b, ok := value.([]byte)
	if !ok {
		return stacktrace.NewError("type assertion to []byte failed")
	}
	return json.Unmarshal(b, &la)
}

// DeleteLocationTagRequest is request structure for deleting a location tag
type DeleteLocationTagRequest struct {
	ID      uuid.UUID `json:"id" binding:"required"`
	OwnerID int64     // should be populated from req headers
}

// GetLocationTagDiffRequest is request struct for fetching locationTag changes
type GetLocationTagDiffRequest struct {
	// SinceTime *int64. Pointer allows us to pass 0 value otherwise binding fails for zero Value.
	SinceTime *int64 `form:"sinceTime" binding:"required"`
	Limit     int16  `form:"limit" binding:"required"`
	OwnerID   int64  // should be populated from req headers
}
