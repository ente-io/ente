package ente

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
	DisableCFWorker     bool   `json:"disableCFWorker"`
	MapEnabled          bool   `json:"mapEnabled"`
	FaceSearchEnabled   bool   `json:"faceSearchEnabled"`
	PassKeyEnabled      bool   `json:"passKeyEnabled"`
	RecoveryKeyVerified bool   `json:"recoveryKeyVerified"`
	InternalUser        bool   `json:"internalUser"`
	BetaUser            bool   `json:"betaUser"`
	EnableMobMultiPart  bool   `json:"enableMobMultiPart"`
	CastUrl             string `json:"castUrl"`
}

type FlagKey string

const (
	RecoveryKeyVerified FlagKey = "recoveryKeyVerified"
	MapEnabled          FlagKey = "mapEnabled"
	FaceSearchEnabled   FlagKey = "faceSearchEnabled"
	PassKeyEnabled      FlagKey = "passKeyEnabled"
	IsInternalUser      FlagKey = "internalUser"
	IsBetaUser          FlagKey = "betaUser"
)

func (k FlagKey) String() string {
	return string(k)
}

// UserEditable returns true if the key is user editable
func (k FlagKey) UserEditable() bool {
	switch k {
	case RecoveryKeyVerified, MapEnabled, FaceSearchEnabled, PassKeyEnabled:
		return true
	default:
		return false
	}
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
	default:
		return false
	}
}
