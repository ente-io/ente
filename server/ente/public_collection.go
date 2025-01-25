package ente

import (
	"database/sql/driver"
	"encoding/json"

	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
)

// CreatePublicAccessTokenRequest payload for creating accessToken for public albums
type CreatePublicAccessTokenRequest struct {
	CollectionID  int64 `json:"collectionID" binding:"required"`
	EnableCollect bool  `json:"enableCollect"`
	// defaults to false
	EnableJoin  *bool `json:"enableJoin"`
	ValidTill   int64 `json:"validTill"`
	DeviceLimit int   `json:"deviceLimit"`
}

type UpdatePublicAccessTokenRequest struct {
	CollectionID    int64   `json:"collectionID" binding:"required"`
	ValidTill       *int64  `json:"validTill"`
	DeviceLimit     *int    `json:"deviceLimit"`
	PassHash        *string `json:"passHash"`
	Nonce           *string `json:"nonce"`
	MemLimit        *int64  `json:"memLimit"`
	OpsLimit        *int64  `json:"opsLimit"`
	EnableDownload  *bool   `json:"enableDownload"`
	EnableCollect   *bool   `json:"enableCollect"`
	DisablePassword *bool   `json:"disablePassword"`
	EnableJoin      *bool   `json:"enableJoin"`
}

type VerifyPasswordRequest struct {
	PassHash string `json:"passHash" binding:"required"`
}

type VerifyPasswordResponse struct {
	JWTToken string `json:"jwtToken"`
}

// PublicCollectionToken represents row entity for public_collection_token table
type PublicCollectionToken struct {
	ID             int64
	CollectionID   int64
	Token          string
	DeviceLimit    int
	ValidTill      int64
	IsDisabled     bool
	PassHash       *string
	Nonce          *string
	MemLimit       *int64
	OpsLimit       *int64
	EnableDownload bool
	EnableCollect  bool
	EnableJoin     bool
}

func (p PublicCollectionToken) CanJoin() error {
	if p.IsDisabled {
		return NewBadRequestWithMessage("link disabled")
	}
	if p.ValidTill > 0 && p.ValidTill < time.Microseconds() {
		return NewBadRequestWithMessage("token expired")
	}
	if !p.EnableDownload {
		return NewBadRequestWithMessage("can not join as download is disabled")
	}
	if !p.EnableJoin {
		return NewBadRequestWithMessage("can not join as join is disabled")
	}
	return nil
}

// PublicURL represents information about non-disabled public url for a collection
type PublicURL struct {
	URL            string `json:"url"`
	DeviceLimit    int    `json:"deviceLimit"`
	ValidTill      int64  `json:"validTill"`
	EnableDownload bool   `json:"enableDownload"`
	// Enable collect indicates whether folks can upload files in a publicly shared url
	EnableCollect   bool `json:"enableCollect"`
	PasswordEnabled bool `json:"passwordEnabled"`
	// Nonce contains the nonce value for the password if the link is password protected.
	Nonce      *string `json:"nonce,omitempty"`
	MemLimit   *int64  `json:"memLimit,omitempty"`
	OpsLimit   *int64  `json:"opsLimit,omitempty"`
	EnableJoin bool    `json:"enableJoin"`
}

type PublicAccessContext struct {
	ID           int64
	IP           string
	UserAgent    string
	CollectionID int64
}

// PublicCollectionSummary represents an information about a public collection
type PublicCollectionSummary struct {
	ID                int64
	CollectionID      int64
	IsDisabled        bool
	ValidTill         int64
	DeviceLimit       int
	CreatedAt         int64
	UpdatedAt         int64
	DeviceAccessCount int
	// not empty value of passHash indicates that the link is password protected.
	PassHash *string
}

type AbuseReportRequest struct {
	URL     string             `json:"url" binding:"required"`
	Reason  string             `json:"reason" binding:"required"`
	Details AbuseReportDetails `json:"details" binding:"required"`
}

type AbuseReportDetails struct {
	FullName   string           `json:"fullName" binding:"required"`
	Email      string           `json:"email" binding:"required"`
	Signature  string           `json:"signature" binding:"required"`
	Comment    string           `json:"comment"`
	OnBehalfOf string           `json:"onBehalfOf"`
	JobTitle   string           `json:"jobTitle"`
	Address    *ReporterAddress `json:"address"`
}

type ReporterAddress struct {
	Stress     string `json:"street" binding:"required"`
	City       string `json:"city" binding:"required"`
	State      string `json:"state" binding:"required"`
	Country    string `json:"country" binding:"required"`
	PostalCode string `json:"postalCode" binding:"required"`
	Phone      string `json:"phone" binding:"required"`
}

// Value implements the driver.Valuer interface. This method
// simply returns the JSON-encoded representation of the struct.
func (ca AbuseReportDetails) Value() (driver.Value, error) {
	return json.Marshal(ca)
}

// Scan implements the sql.Scanner interface. This method
// simply decodes a JSON-encoded value into the struct fields.
func (ca *AbuseReportDetails) Scan(value interface{}) error {
	b, ok := value.([]byte)
	if !ok {
		return stacktrace.NewError("type assertion to []byte failed")
	}

	return json.Unmarshal(b, &ca)
}

// Value implements the driver.Valuer interface. This method
// simply returns the JSON-encoded representation of the struct.
func (ca ReporterAddress) Value() (driver.Value, error) {
	return json.Marshal(ca)
}

// Scan implements the sql.Scanner interface. This method
// simply decodes a JSON-encoded value into the struct fields.
func (ca *ReporterAddress) Scan(value interface{}) error {
	b, ok := value.([]byte)
	if !ok {
		return stacktrace.NewError("type assertion to []byte failed")
	}

	return json.Unmarshal(b, &ca)
}
