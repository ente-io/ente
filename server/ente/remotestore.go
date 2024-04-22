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

type FeatureFlagResponse struct {
	EnableStripe bool `json:"enableStripe"`
	// If true, the mobile client will stop using CF worker to download files
	DisableCFWorker     bool `json:"disableCFWorker"`
	MapEnabled          bool `json:"mapEnabled"`
	FaceSearchEnabled   bool `json:"faceSearchEnabled"`
	PassKeyEnabled      bool `json:"passKeyEnabled"`
	RecoveryKeyVerified bool `json:"recoveryKeyVerified"`
	InternalUser        bool `json:"internalUser"`
	BetaUser            bool `json:"betaUser"`
}

type FlagKey string

const (
	RecoveryKeyVerified FlagKey = "recoveryKeyVerified"
	MapEnabled          FlagKey = "mapEnabled"
	FaceSearchEnabled   FlagKey = "faceSearchEnabled"
	PassKeyEnabled      FlagKey = "passKeyEnabled"
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

func (k FlagKey) IsBoolType() bool {
	switch k {
	case RecoveryKeyVerified, MapEnabled, FaceSearchEnabled, PassKeyEnabled:
		return true
	default:
		return false
	}
}
