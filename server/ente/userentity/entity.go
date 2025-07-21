package userentity

import (
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/ente/base"
	"strings"
)

type EntityType string

const (
	Location EntityType = "location"
	// Person entity is deprecated and will be removed in the future.
	//Deprecated ..
	Person EntityType = "person"
	// CGroup is a new version of Person entity, where the data is gzipped before encryption
	CGroup EntityType = "cgroup"
	// SmartAlbum is a new entity type for storing smart album config data
	SmartAlbum EntityType = "smart_album"
)

func (et EntityType) IsValid() error {
	switch et {
	case Location, Person, CGroup, SmartAlbum:
		return nil
	}
	return ente.NewBadRequestWithMessage(fmt.Sprintf("Invalid EntityType: %s", et))
}

func (et EntityType) GetNewID() (*string, error) {
	return base.NewID(strings.ToLower(string(et)))
}

type EntityKey struct {
	UserID       int64      `json:"userID" binding:"required"`
	Type         EntityType `json:"type" binding:"required"`
	EncryptedKey string     `json:"encryptedKey" binding:"required"`
	Header       string     `json:"header" binding:"required"`
	CreatedAt    int64      `json:"createdAt" binding:"required"`
}

// EntityData represents a single UserEntity
type EntityData struct {
	ID            string     `json:"id" binding:"required"`
	UserID        int64      `json:"userID" binding:"required"`
	Type          EntityType `json:"type" binding:"required"`
	EncryptedData *string    `json:"encryptedData" binding:"required"`
	Header        *string    `json:"header" binding:"required"`
	IsDeleted     bool       `json:"isDeleted" binding:"required"`
	CreatedAt     int64      `json:"createdAt" binding:"required"`
	UpdatedAt     int64      `json:"updatedAt" binding:"required"`
}

// EntityKeyRequest represents a request to create entity data encryption key for a given EntityType
type EntityKeyRequest struct {
	Type         EntityType `json:"type" binding:"required"`
	EncryptedKey string     `json:"encryptedKey" binding:"required"`
	Header       string     `json:"header" binding:"required"`
}

// GetEntityKeyRequest represents a request to get entity key for given EntityType
type GetEntityKeyRequest struct {
	Type EntityType `form:"type" binding:"required"`
}

// EntityDataRequest is used to create a new entity data of given EntityType
type EntityDataRequest struct {
	Type          EntityType `json:"type" binding:"required"`
	EncryptedData string     `json:"encryptedData" binding:"required"`
	Header        string     `json:"header" binding:"required"`
}

// UpdateEntityDataRequest updates the current entity
type UpdateEntityDataRequest struct {
	ID            string     `json:"id" binding:"required"`
	Type          EntityType `json:"type" binding:"required"`
	EncryptedData string     `json:"encryptedData" binding:"required"`
	Header        string     `json:"header" binding:"required"`
}

// GetEntityDiffRequest returns the diff of entities since the given time
type GetEntityDiffRequest struct {
	Type EntityType `form:"type" binding:"required"`
	// SinceTime *int64. Pointer allows us to pass 0 value otherwise binding fails for zero Value.
	SinceTime *int64 `form:"sinceTime" binding:"required"`
	Limit     int16  `form:"limit" binding:"required"`
}
