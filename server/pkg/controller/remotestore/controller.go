package remotestore

import (
	"database/sql"
	"errors"
	"fmt"
	"github.com/spf13/viper"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo/remotestore"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// Controller is interface for exposing business logic related to for remote store
type Controller struct {
	Repo *remotestore.Repository
}

// InsertOrUpdate the key's value
func (c *Controller) InsertOrUpdate(ctx *gin.Context, request ente.UpdateKeyValueRequest) error {
	if err := _validateRequest(request.Key, request.Value, false); err != nil {
		return err
	}
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.InsertOrUpdate(ctx, userID, request.Key, request.Value)
}

func (c *Controller) AdminInsertOrUpdate(ctx *gin.Context, request ente.AdminUpdateKeyValueRequest) error {
	if err := _validateRequest(request.Key, request.Value, true); err != nil {
		return err
	}
	return c.Repo.InsertOrUpdate(ctx, request.UserID, request.Key, request.Value)
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
		// When true, users will see an option to enable multiple part upload in the app
		// Changing it to false will hide the option and disable multi part upload for everyone
		// except internal user.rt
		EnableMobMultiPart: true,
		CastUrl:            viper.GetString("apps.cast"),
	}
	for key, value := range values {
		flag := ente.FlagKey(key)
		if !flag.IsBoolType() {
			continue
		}
		switch flag {
		case ente.RecoveryKeyVerified:
			response.RecoveryKeyVerified = value == "true"
		case ente.MapEnabled:
			response.MapEnabled = value == "true"
		case ente.FaceSearchEnabled:
			response.FaceSearchEnabled = value == "true"
		case ente.PassKeyEnabled:
			response.PassKeyEnabled = value == "true"
		case ente.IsInternalUser:
			response.InternalUser = value == "true"
		case ente.IsBetaUser:
			response.BetaUser = value == "true"
		}
	}
	return response, nil
}

func _validateRequest(key, value string, byAdmin bool) error {
	flag := ente.FlagKey(key)
	if !flag.UserEditable() && !byAdmin {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not user editable", key)), "key not user editable")
	}
	if byAdmin && !flag.IsAdminEditable() {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not admin editable", key)), "key not admin editable")
	}
	if flag.IsBoolType() && value != "true" && value != "false" {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("value %s is not allowed", value)), "value not allowed")
	}
	return nil
}
