package remotestore

import (
	"database/sql"
	"errors"

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

// Insert of update the key's value
func (c *Controller) InsertOrUpdate(ctx *gin.Context, request ente.UpdateKeyValueRequest) error {
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
