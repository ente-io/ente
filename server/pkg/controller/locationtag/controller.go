package locationtag

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo/locationtag"
	"github.com/gin-gonic/gin"
)

// Controller is interface for exposing business logic related to location tags
type Controller struct {
	Repo *locationtag.Repository
}

// Create a new location tag in the system
func (c *Controller) Create(ctx *gin.Context, req ente.LocationTag) (ente.LocationTag, error) {
	return c.Repo.Create(ctx, req)
}
func (c *Controller) Update(ctx *gin.Context, req ente.LocationTag) (ente.LocationTag, error) {
	// todo: verify ownership before updating
	panic("implement me")
}

// Delete the location tag for the given id and ownerId
func (c *Controller) Delete(ctx *gin.Context, req ente.DeleteLocationTagRequest) (bool, error) {
	return c.Repo.Delete(ctx, req.ID.String(), req.OwnerID)
}

// GetDiff fetches the locationTags which have changed after the specified time
func (c *Controller) GetDiff(ctx *gin.Context, req ente.GetLocationTagDiffRequest) ([]ente.LocationTag, error) {
	return c.Repo.GetDiff(ctx, req.OwnerID, *req.SinceTime, req.Limit)
}
