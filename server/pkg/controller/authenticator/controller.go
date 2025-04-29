package authenticaor

import (
	"errors"
	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/authenticator"
	"github.com/ente-io/museum/pkg/repo/authenticator"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/google/uuid"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Controller is interface for exposing business logic related to authenticator app
type Controller struct {
	Repo *authenticator.Repository
}

// CreateKey...
func (c *Controller) CreateKey(ctx *gin.Context, req model.CreateKeyRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.CreateKey(ctx, userID, req)
}

// GetKey...
func (c *Controller) GetKey(ctx *gin.Context) (*model.Key, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	res, err := c.Repo.GetKey(ctx, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &res, nil
}

// CreateEntity...
func (c *Controller) CreateEntity(ctx *gin.Context, req model.CreateEntityRequest) (*model.Entity, error) {
	if err := c.validateKey(ctx); err != nil {
		return nil, stacktrace.Propagate(err, "failed to validateKey")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	id, err := c.Repo.Create(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to createEntity")
	}
	entity, err := c.Repo.Get(ctx, userID, id)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to createEntity")
	}
	return &entity, nil
}

// UpdateEntity...
func (c *Controller) UpdateEntity(ctx *gin.Context, req model.UpdateEntityRequest) error {
	if err := c.validateKey(ctx); err != nil {
		return stacktrace.Propagate(err, "failed to validateKey")
	}
	userID := auth.GetUserID(ctx.Request.Header)

	return c.Repo.Update(ctx, userID, req)
}

func (c *Controller) validateKey(ctx *gin.Context) error {
	userID := auth.GetUserID(ctx.Request.Header)
	_, err := c.Repo.GetKey(ctx, userID)
	if err != nil && errors.Is(err, &ente.ErrNotFoundError) {
		return stacktrace.Propagate(&ente.ApiError{
			Code:           ente.AuthKeyNotCreated,
			Message:        "AuthKey is not created",
			HttpStatusCode: http.StatusBadRequest,
		}, "")
	}
	return err
}

// Delete...
func (c *Controller) Delete(ctx *gin.Context, entityID uuid.UUID) (bool, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.Delete(ctx, userID, entityID)
}

// GetDiff...
func (c *Controller) GetDiff(ctx *gin.Context, req model.GetEntityDiffRequest) ([]model.Entity, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.GetDiff(ctx, userID, *req.SinceTime, req.Limit)
}
