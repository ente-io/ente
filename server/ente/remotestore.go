package ente

import (
	"fmt"
	"github.com/ente-io/stacktrace"
	"regexp"
	"strings"
)

type GetValueRequest struct {
	Key          string  `form:"key" binding:"required"`
	DefaultValue *string `form:"defaultValue"`
}

type GetValueResponse struct {
	Value string `json:"value" binding:"required"`
}

type UpdateKeyValueRequest struct {
	Key   string  `json:"key" binding:"required"`
	Value *string `json:"value" binding:"required"`
}

type AdminUpdateKeyValueRequest struct {
	UserID int64   `json:"userID" binding:"required"`
	Key    string  `json:"key" binding:"required"`
	Value  *string `json:"value" binding:"required"`
}

type FeatureFlagResponse struct {
	EnableStripe bool `json:"enableStripe"`
	// If true, the mobile client will stop using CF worker to download files
	DisableCFWorker     bool    `json:"disableCFWorker"`
	MapEnabled          bool    `json:"mapEnabled"`
	FaceSearchEnabled   bool    `json:"faceSearchEnabled"`
	PassKeyEnabled      bool    `json:"passKeyEnabled"`
	RecoveryKeyVerified bool    `json:"recoveryKeyVerified"`
	InternalUser        bool    `json:"internalUser"`
	BetaUser            bool    `json:"betaUser"`
	EnableMobMultiPart  bool    `json:"enableMobMultiPart"`
	CastUrl             string  `json:"castUrl"`
	CustomDomain        *string `json:"customDomain,omitempty"`
	CustomDomainCNAME   string  `json:"customDomainCNAME,omitempty"`
}

type FlagKey string

const (
	RecoveryKeyVerified FlagKey = "recoveryKeyVerified"
	MapEnabled          FlagKey = "mapEnabled"
	FaceSearchEnabled   FlagKey = "faceSearchEnabled"
	PassKeyEnabled      FlagKey = "passKeyEnabled"
	IsInternalUser      FlagKey = "internalUser"
	IsBetaUser          FlagKey = "betaUser"
	CustomDomain        FlagKey = "customDomain"
)

var validFlagKeys = map[FlagKey]struct{}{
	RecoveryKeyVerified: {},
	MapEnabled:          {},
	FaceSearchEnabled:   {},
	PassKeyEnabled:      {},
	IsInternalUser:      {},
	IsBetaUser:          {},
	CustomDomain:        {},
}

func IsValidFlagKey(key string) bool {
	_, exists := validFlagKeys[FlagKey(key)]
	return exists
}

func (k FlagKey) String() string {
	return string(k)
}

// UserEditable returns true if the key is user editable
func (k FlagKey) UserEditable() bool {
	switch k {
	case RecoveryKeyVerified, MapEnabled, FaceSearchEnabled, PassKeyEnabled, CustomDomain:
		return true
	default:
		return false
	}
}

func (k FlagKey) NeedSubscription() bool {
	return k == CustomDomain
}

func (k FlagKey) CanRemove() bool {
	return k == CustomDomain
}

func (k FlagKey) IsAdminEditable() bool {
	switch k {
	case RecoveryKeyVerified, MapEnabled, FaceSearchEnabled:
		return false
	case IsInternalUser, IsBetaUser, PassKeyEnabled:
		return true
	default:
		return true
	}
}

func (k FlagKey) IsBoolType() bool {
	switch k {
	case RecoveryKeyVerified, MapEnabled, FaceSearchEnabled, PassKeyEnabled, IsInternalUser, IsBetaUser:
		return true
	case CustomDomain:
		return false
	default:
		return false // Explicitly handle unexpected cases
	}
}

func (k FlagKey) IsValidValue(value string) error {
	if k.IsBoolType() && value != "true" && value != "false" {
		return stacktrace.Propagate(NewBadRequestWithMessage(fmt.Sprintf("value %s is not allowed", value)), "value not allowed")
	}
	if k == CustomDomain && value != "" {
		if err := isValidDomainWithoutScheme(value); err != nil {
			return stacktrace.Propagate(err, "invalid custom domain")
		}
	}
	return nil
}

var domainRegex = regexp.MustCompile(`^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$`)

func isValidDomainWithoutScheme(input string) error {
	trimmed := strings.TrimSpace(input)
	if trimmed != input {
		return NewBadRequestWithMessage("domain contains leading or trailing spaces")
	}
	if trimmed == "" {
		return NewBadRequestWithMessage("domain is empty")
	}
	if strings.Contains(trimmed, "://") {
		return NewBadRequestWithMessage("domain should not contain scheme (e.g., http:// or https://)")
	}
	if !domainRegex.MatchString(trimmed) {
		return NewBadRequestWithMessage(fmt.Sprintf("invalid domain format: %s", trimmed))
	}
	return nil
}
