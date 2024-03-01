package access

import (
	"github.com/ente-io/museum/ente"
	enteArray "github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type VerifyFileOwnershipParams struct {
	// userID of the user trying to fetch the controller
	ActorUserId int64
	FileIDs     []int64
}

// VerifyFileOwnership will return error if given fileIDs are not valid or don't belong to the ownerID
func (c controllerImpl) VerifyFileOwnership(ctx *gin.Context, req *VerifyFileOwnershipParams) error {
	if enteArray.ContainsDuplicateInInt64Array(req.FileIDs) {
		return stacktrace.Propagate(ente.ErrBadRequest, "duplicate fileIDs")
	}
	ownerID := req.ActorUserId
	logger := log.WithFields(log.Fields{
		"req_id": requestid.Get(ctx),
	})
	return c.FileRepo.VerifyFileOwner(ctx, req.FileIDs, ownerID, logger)
}
