package remotestore

import (
	"database/sql"
	"errors"
	"fmt"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo/remotestore"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

type FlagKey string

const (
	RecoveryKeyVerified FlagKey = "recoveryKeyVerified"
	MapEnabled          FlagKey = "mapEnabled"
	FaceSearchEnabled   FlagKey = "faceSearchEnabled"
	PassKeyEnabled      FlagKey = "passKeyEnabled"
)

func isBoolType(key FlagKey) bool {
	switch key {
	case RecoveryKeyVerified, MapEnabled, FaceSearchEnabled, PassKeyEnabled:
		return true
	default:
		return false
	}
}

var (
	_allowKeys = map[FlagKey]*bool{
		RecoveryKeyVerified: nil,
		MapEnabled:          nil,
		FaceSearchEnabled:   nil,
		PassKeyEnabled:      nil,
	}
)

// Controller is interface for exposing business logic related to for remote store
type Controller struct {
	Repo *remotestore.Repository
}

// InsertOrUpdate the key's value
func (c *Controller) InsertOrUpdate(ctx *gin.Context, request ente.UpdateKeyValueRequest) error {
	if err := _validateRequest(request); err != nil {
		return err
	}
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.InsertOrUpdate(ctx, userID, request.Key, request.Value)
}

func (c *Controller) Get(ctx *gin.Context, req ente.GetValueRequest) (*ente.GetValueResponse, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	value, err := c.Repo.GetValue(ctx, userID, req.Key)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) && req.DefaultValue != nil {
			return &ente.GetValueResponse{Value: *req.DefaultValue}, nil
		} else {
			return nil, stacktrace.Propagate(err, "")
		}
	}
	return &ente.GetValueResponse{Value: value}, nil
}

func (c *Controller) GetFeatureFlags(ctx *gin.Context) (*ente.FeatureFlagResponse, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	values, err := c.Repo.GetAllValues(ctx, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	response := &ente.FeatureFlagResponse{
		EnableStripe:    true, // enable stripe for all
		DisableCFWorker: false,
	}
	for key, value := range values {
		flag := FlagKey(key)
		if !isBoolType(flag) {
			continue
		}
		switch flag {
		case RecoveryKeyVerified:
			response.RestoreKeyVerified = value == "true"
		case MapEnabled:
			response.MapEnabled = value == "true"
		case FaceSearchEnabled:
			response.FaceSearchEnabled = value == "true"
		case PassKeyEnabled:
			response.PassKeyEnabled = value == "true"
		}
	}
	return response, nil
}

func _validateRequest(request ente.UpdateKeyValueRequest) error {
	flag := FlagKey(request.Key)
	if _, ok := _allowKeys[flag]; !ok {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not allowed", request.Key)), "key not allowed")
	}
	if isBoolType(flag) && request.Value != "true" && request.Value != "false" {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("value %s is not allowed", request.Value)), "value not allowed")
	}
	return nil
}
