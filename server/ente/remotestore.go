package ente

import (
	"fmt"
	"github.com/ente-io/stacktrace"
	"net/url"
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
	Key   string `json:"key" binding:"required"`
	Value string `json:"value" binding:"required"`
}

type AdminUpdateKeyValueRequest struct {
	UserID int64  `json:"userID" binding:"required"`
	Key    string `json:"key" binding:"required"`
	Value  string `json:"value" binding:"required"`
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
		if !isValidCustomDomainURL(value) {
			return stacktrace.Propagate(NewBadRequestWithMessage(fmt.Sprintf("invalid domain fmt: %s", value)), "url with https://. Also, tt should not end with trailing dash.")
		}
	}
	return nil
}

func isValidCustomDomainURL(input string) bool {
	if !strings.HasPrefix(input, "https://") || strings.HasSuffix(input, "/") {
		return false
	}

	u, err := url.Parse(input)
	if err != nil || u.Scheme != "https" || u.Host == "" {
		return false
	}

	return true
}
