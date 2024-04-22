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

func _validateRequest(request ente.UpdateKeyValueRequest) error {
	if _, ok := _allowKeys[FlagKey(request.Key)]; !ok {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not allowed", request.Key)), "key not allowed")
	}
	if request.Value != "true" && request.Value != "false" {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("value %s is not allowed", request.Value)), "value not allowed")
	}
	return nil
}
