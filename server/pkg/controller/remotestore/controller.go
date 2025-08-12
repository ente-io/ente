package remotestore

import (
	"database/sql"
	"errors"
	"fmt"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/spf13/viper"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo/remotestore"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// Controller is interface for exposing business logic related to for remote store
type Controller struct {
	Repo        *remotestore.Repository
	BillingCtrl *controller.BillingController
}

// InsertOrUpdate the key's value
func (c *Controller) InsertOrUpdate(ctx *gin.Context, request ente.UpdateKeyValueRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	if err := c._validateRequest(userID, request.Key, request.Value, false); err != nil {
		return err
	}
	if *request.Value == "" && ente.FlagKey(request.Key).CanRemove() {
		return c.Repo.RemoveKey(ctx, userID, request.Key)
	}
	return c.Repo.InsertOrUpdate(ctx, userID, request.Key, *request.Value)
}

// RemoveKey removes the key from remote store
func (c *Controller) RemoveKey(ctx *gin.Context, key string) error {
	userID := auth.GetUserID(ctx.Request.Header)
	if valid := ente.IsValidFlagKey(key); !valid {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not allowed", key)), "invalid flag key")
	}
	if !ente.FlagKey(key).CanRemove() {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not removable", key)), "key not removable")
	}
	return c.Repo.RemoveKey(ctx, userID, key)
}

func (c *Controller) AdminInsertOrUpdate(ctx *gin.Context, request ente.AdminUpdateKeyValueRequest) error {
	if err := c._validateRequest(request.UserID, request.Key, request.Value, true); err != nil {
		return err
	}
	return c.Repo.InsertOrUpdate(ctx, request.UserID, request.Key, *request.Value)
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
		CustomDomainCNAME:  viper.GetString("apps.custom-domain.cname"),
	}
	for key, value := range values {
		flag := ente.FlagKey(key)
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
		case ente.CustomDomain:
			if value != "" {
				response.CustomDomain = &value
			}
		}
	}
	return response, nil
}

func (c *Controller) DomainOwner(ctx *gin.Context, domain string) (*int64, error) {
	return c.Repo.DomainOwner(ctx, domain)
}

func (c *Controller) _validateRequest(userID int64, key string, valuePtr *string, byAdmin bool) error {
	if !ente.IsValidFlagKey(key) {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not allowed", key)), "invalid flag key")
	}
	if valuePtr == nil {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("value is missing"), "value is nil")
	}
	value := *valuePtr
	flag := ente.FlagKey(key)
	if err := flag.IsValidValue(value); err != nil {
		return stacktrace.Propagate(err, "")
	}
	if !flag.UserEditable() && !byAdmin {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not user editable", key)), "key not user editable")
	}
	if byAdmin && !flag.IsAdminEditable() {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("key %s is not admin editable", key)), "key not admin editable")
	}

	if flag.NeedSubscription() {
		return c.BillingCtrl.HasActiveSelfOrFamilySubscription(userID, true)
	}
	return nil
}
