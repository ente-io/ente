package authenticaor

import (
	model "github.com/ente-io/museum/ente/userentity"
	"github.com/ente-io/museum/pkg/repo/userentity"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// Controller is interface for exposing business logic related to authenticator app
type Controller struct {
	Repo *userentity.Repository
}

// CreateKey stores an entity key for the given type
func (c *Controller) CreateKey(ctx *gin.Context, req model.EntityKeyRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.CreateKey(ctx, userID, req)
}

// GetKey
func (c *Controller) GetKey(ctx *gin.Context, req model.GetEntityKeyRequest) (*model.EntityKey, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	res, err := c.Repo.GetKey(ctx, userID, req.Type)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &res, nil
}

// CreateEntity stores entity data for the given type
func (c *Controller) CreateEntity(ctx *gin.Context, req model.EntityDataRequest) (*model.EntityData, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	if err := req.IsValid(userID); err != nil {
		return nil, stacktrace.Propagate(err, "invalid EntityDataRequest")
	}
	id, err := c.Repo.Create(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to createEntity")
	}
	return c.Repo.Get(ctx, userID, id)
}

// UpdateEntity...
func (c *Controller) UpdateEntity(ctx *gin.Context, req model.UpdateEntityDataRequest) (*model.EntityData, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	err := c.Repo.Update(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to updateEntity")
	}
	return c.Repo.Get(ctx, userID, req.ID)
}

// Delete...
func (c *Controller) Delete(ctx *gin.Context, entityID string) (bool, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.Delete(ctx, userID, entityID)
}

// GetDiff returns diff of EntityData for the given type
func (c *Controller) GetDiff(ctx *gin.Context, req model.GetEntityDiffRequest) ([]model.EntityData, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.GetDiff(ctx, userID, req.Type, *req.SinceTime, req.Limit)
}
