package api

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/gin-gonic/gin"
)

// CollectionHandler exposes request handlers for all collection related requests
type CollectionHandler struct {
	Controller *controller.CollectionController
}

// Create creates a collection
func (h *CollectionHandler) Create(c *gin.Context) {
	log.Info("Collection create")
	var collection ente.Collection
	if err := c.ShouldBindJSON(&collection); err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Could not bind request params"))
		return
	}

	collection.App = string(auth.GetApp(c))
	collection.UpdationTime = time.Microseconds()
	collection, err := h.Controller.Create(collection,
		auth.GetUserID(c.Request.Header))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Could not create collection"))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"collection": collection,
	})
}

// GetCollectionByID returns the collection for given ID.
func (h *CollectionHandler) GetCollectionByID(c *gin.Context) {
	cID, err := strconv.ParseInt(c.Param("collectionID"), 10, 64)
	if err != nil {
		handler.Error(c, ente.ErrBadRequest)
		return
	}
	userID := auth.GetUserID(c.Request.Header)
	collection, err := h.Controller.GetCollection(c, userID, cID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"collection": collection,
	})
}

// Deprecated: Remove once rps goes to 0.
// Get returns the list of collections accessible to a user.
func (h *CollectionHandler) Get(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	sinceTime, _ := strconv.ParseInt(c.Query("sinceTime"), 10, 64)

	app := auth.GetApp(c)

	// TODO: Compute both with a single query
	ownedCollections, err := h.Controller.GetOwned(userID, sinceTime, app)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get owned collections"))
		return
	}
	sharedCollections, err := h.Controller.GetSharedWith(userID, sinceTime, app)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get shared collections"))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"collections": append(ownedCollections, sharedCollections...),
	})
}

// GetV2 returns the list of collections accessible to a user
func (h *CollectionHandler) GetV2(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	sinceTime, _ := strconv.ParseInt(c.Query("sinceTime"), 10, 64)
	app := auth.GetApp(c)
	ownedCollections, err := h.Controller.GetOwnedV2(userID, sinceTime, app)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get owned collections"))
		return
	}
	sharedCollections, err := h.Controller.GetSharedWith(userID, sinceTime, app)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get shared collections"))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"collections": append(ownedCollections, sharedCollections...),
	})
}

// Share shares a collection with a user
func (h *CollectionHandler) Share(c *gin.Context) {
	var request ente.AlterShareRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	resp, err := h.Controller.Share(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"sharees": resp,
	})
}

func (h *CollectionHandler) JoinLink(c *gin.Context) {
	var request ente.JoinCollectionViaLinkRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	err := h.Controller.JoinViaLink(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

// ShareURL generates a publicly sharable url
func (h *CollectionHandler) ShareURL(c *gin.Context) {
	var request ente.CreatePublicAccessTokenRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	response, err := h.Controller.ShareURL(c, auth.GetUserID(c.Request.Header), request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"result": response,
	})
}

// UpdateShareURL generates a publicly sharable url
func (h *CollectionHandler) UpdateShareURL(c *gin.Context) {
	var req ente.UpdatePublicAccessTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if req.DeviceLimit == nil && req.ValidTill == nil && req.DisablePassword == nil &&
		req.Nonce == nil && req.PassHash == nil && req.EnableDownload == nil && req.EnableCollect == nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "all parameters are missing"))
		return
	}

	if req.DeviceLimit != nil && (*req.DeviceLimit < 0 || *req.DeviceLimit > controller.DeviceLimitThreshold) {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("device limit: %d out of range", *req.DeviceLimit)))
		return
	}

	if req.ValidTill != nil && *req.ValidTill != 0 && *req.ValidTill < time.Microseconds() {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "valid till should be greater than current timestamp"))
		return
	}

	var allPassParamsMissing = req.Nonce == nil && req.PassHash == nil && req.MemLimit == nil && req.OpsLimit == nil
	var allPassParamsPresent = req.Nonce != nil && req.PassHash != nil && req.MemLimit != nil && req.OpsLimit != nil

	if !(allPassParamsMissing || allPassParamsPresent) {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "all password params should be either present or missing"))
		return
	}

	if allPassParamsPresent && req.DisablePassword != nil && *req.DisablePassword {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "can not set and disable password in same request"))
		return
	}

	response, err := h.Controller.UpdateShareURL(c, auth.GetUserID(c.Request.Header), req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"result": response,
	})
}

// UnShareURL disable all shared urls for the given collectionID
func (h *CollectionHandler) UnShareURL(c *gin.Context) {
	cID, err := strconv.ParseInt(c.Param("collectionID"), 10, 64)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
		return
	}
	userID := auth.GetUserID(c.Request.Header)
	err = h.Controller.DisableSharedURL(c, userID, cID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// UnShare unshares a collection with a user
func (h *CollectionHandler) UnShare(c *gin.Context) {
	var request ente.AlterShareRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	resp, err := h.Controller.UnShare(c, request.CollectionID, auth.GetUserID(c.Request.Header), request.Email)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"sharees": resp,
	})
}

// Leave allows user to leave a shared collection, which is not owned by them
func (h *CollectionHandler) Leave(c *gin.Context) {
	cID, err := strconv.ParseInt(c.Param("collectionID"), 10, 64)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
		return
	}
	err = h.Controller.Leave(c, cID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// AddFiles adds files to a collection
func (h *CollectionHandler) AddFiles(c *gin.Context) {
	var request ente.AddFilesRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if len(request.Files) > DefaultMaxBatchSize {
		handler.Error(c, stacktrace.Propagate(ente.ErrBatchSizeTooLarge, ""))
		return
	}

	if err := h.Controller.AddFiles(c, auth.GetUserID(c.Request.Header), request.Files, request.CollectionID); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// RestoreFiles adds files from trash to given collection
func (h *CollectionHandler) RestoreFiles(c *gin.Context) {
	var request ente.AddFilesRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	if len(request.Files) > DefaultMaxBatchSize {
		handler.Error(c, stacktrace.Propagate(ente.ErrBatchSizeTooLarge, ""))
		return
	}

	if err := h.Controller.RestoreFiles(c, auth.GetUserID(c.Request.Header), request.CollectionID, request.Files); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// Movefiles from one collection to another
func (h *CollectionHandler) MoveFiles(c *gin.Context) {
	var request ente.MoveFilesRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	if len(request.Files) > DefaultMaxBatchSize {
		handler.Error(c, stacktrace.Propagate(ente.ErrBatchSizeTooLarge, ""))
		return
	}
	if request.ToCollectionID == request.FromCollectionID {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "to and fromCollection should be different"))
		return
	}

	if err := h.Controller.MoveFiles(c, request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// RemoveFilesV3 allow removing files from a collection when files and collection belong to two different users
func (h *CollectionHandler) RemoveFilesV3(c *gin.Context) {
	var request ente.RemoveFilesV3Request
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if len(request.FileIDs) > DefaultMaxBatchSize {
		handler.Error(c, stacktrace.Propagate(ente.ErrBatchSizeTooLarge, ""))
		return
	}
	if err := h.Controller.RemoveFilesV3(c, request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// GetDiffV2 returns the diff within a collection since a timestamp
func (h *CollectionHandler) GetDiffV2(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	cID, _ := strconv.ParseInt(c.Query("collectionID"), 10, 64)
	sinceTime, _ := strconv.ParseInt(c.Query("sinceTime"), 10, 64)
	files, hasMore, err := h.Controller.GetDiffV2(c, cID, userID, sinceTime)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"diff":    files,
		"hasMore": hasMore,
	})
}

// GetFile returns the diff within a collection since a timestamp
func (h *CollectionHandler) GetFile(c *gin.Context) {
	cID, _ := strconv.ParseInt(c.Query("collectionID"), 10, 64)
	fileID, _ := strconv.ParseInt(c.Query("fileID"), 10, 64)
	file, err := h.Controller.GetFile(c, cID, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"file": file,
	})
}

// GetSharees returns the list of users a collection has been shared with
func (h *CollectionHandler) GetSharees(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	cID, _ := strconv.ParseInt(c.Query("collectionID"), 10, 64)
	sharees, err := h.Controller.GetSharees(c, cID, userID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"sharees": sharees,
	})
}

func (h *CollectionHandler) TrashV3(c *gin.Context) {
	var req ente.TrashCollectionV3Request
	if err := c.ShouldBindQuery(&req); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}

	err := h.Controller.TrashV3(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// Rename updates the collection's name
func (h *CollectionHandler) Rename(c *gin.Context) {
	var request ente.RenameRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if err := h.Controller.Rename(auth.GetUserID(c.Request.Header), request.CollectionID, request.EncryptedName, request.NameDecryptionNonce); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// Updates the magic metadata for a collection
func (h *CollectionHandler) PrivateMagicMetadataUpdate(c *gin.Context) {
	var request ente.UpdateCollectionMagicMetadata
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if err := h.Controller.UpdateMagicMetadata(c, request, false); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// PublicMagicMetadataUpdate updates the public magic metadata for a collection
func (h *CollectionHandler) PublicMagicMetadataUpdate(c *gin.Context) {
	var request ente.UpdateCollectionMagicMetadata
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if err := h.Controller.UpdateMagicMetadata(c, request, true); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// ShareeMagicMetadataUpdate updates sharees magic metadata for shared collection.
func (h *CollectionHandler) ShareeMagicMetadataUpdate(c *gin.Context) {
	var request ente.UpdateCollectionMagicMetadata
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	err := h.Controller.UpdateShareeMagicMetadata(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}
