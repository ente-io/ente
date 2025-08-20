package api

import (
	"fmt"
	fileData "github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/controller/collections"
	"github.com/ente-io/museum/pkg/controller/filedata"
	"github.com/ente-io/museum/pkg/controller/public"
	"net/http"
	"strconv"

	"github.com/ente-io/museum/pkg/controller/storagebonus"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// PublicCollectionHandler exposes request handlers for publicly accessible collections
type PublicCollectionHandler struct {
	Controller             *public.CollectionLinkController
	FileCtrl               *controller.FileController
	CollectionCtrl         *collections.CollectionController
	FileDataCtrl           *filedata.Controller
	StorageBonusController *storagebonus.Controller
}

// GetThumbnail redirects the request to the file's thumbnail location
func (h *PublicCollectionHandler) GetThumbnail(c *gin.Context) {
	h.getFileForType(c, ente.THUMBNAIL)
}

// GetFile redirects the request to the file location
func (h *PublicCollectionHandler) GetFile(c *gin.Context) {
	h.getFileForType(c, ente.FILE)
}

func (h *PublicCollectionHandler) GetPreviewURL(c *gin.Context) {
	var req fileData.GetPreviewURLRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	collectionOwner, err := h.getCollectionOwnerAndVerifyAccess(c, req.FileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	url, err := h.FileDataCtrl.GetPreviewUrl(c, *collectionOwner, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}

func (h *PublicCollectionHandler) GetFileData(c *gin.Context) {
	var req fileData.GetFileData
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, ente.NewBadRequestWithMessage(err.Error()))
		return
	}
	if req.Type != ente.PreviewVideo {
		errorMessage := fmt.Sprintf("unsupported object type %s", req.Type)
		handler.Error(c, stacktrace.Propagate(ente.NewBadRequestWithMessage(errorMessage), ""))
		return
	}
	collectionOwner, err := h.getCollectionOwnerAndVerifyAccess(c, req.FileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	resp, err := h.FileDataCtrl.GetFileData(c, *collectionOwner, req)
	if err != nil {
		handler.Error(c, err)
		return
	}
	if resp == nil {
		c.Status(http.StatusNoContent)
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"data": resp,
	})
}

func (h *PublicCollectionHandler) getCollectionOwnerAndVerifyAccess(c *gin.Context, fileID int64) (*int64, error) {
	accessContext := auth.MustGetPublicAccessContext(c)
	if accessErr := h.FileCtrl.DoesFileExistInCollection(c, fileID, accessContext.CollectionID); accessErr != nil {
		return nil, stacktrace.Propagate(accessErr, "")
	}
	collection, err := h.Controller.GetPublicCollection(c, false)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &collection.Owner.ID, nil
}

// GetCollection redirects the request to the collection location
func (h *PublicCollectionHandler) GetCollection(c *gin.Context) {
	collection, err := h.Controller.GetPublicCollection(c, false)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	referralCode, _ := h.StorageBonusController.GetOrCreateReferralCode(c, collection.Owner.ID)
	c.JSON(http.StatusOK, gin.H{
		"collection":   collection,
		"referralCode": referralCode,
	})
}

// GetUploadUrls returns upload Urls where files can be uploaded
func (h *PublicCollectionHandler) GetUploadUrls(c *gin.Context) {
	enteApp := auth.GetApp(c)

	collection, err := h.Controller.GetPublicCollection(c, true)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	userID := collection.Owner.ID
	count, _ := strconv.Atoi(c.Query("count"))
	urls, err := h.FileCtrl.GetUploadURLs(c, userID, count, enteApp, false)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"urls": urls,
	})
}

// GetMultipartUploadURLs returns upload Urls where files can be uploaded
func (h *PublicCollectionHandler) GetMultipartUploadURLs(c *gin.Context) {
	enteApp := auth.GetApp(c)

	collection, err := h.Controller.GetPublicCollection(c, true)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	userID := collection.Owner.ID
	count, _ := strconv.Atoi(c.Query("count"))
	urls, err := h.FileCtrl.GetMultipartUploadURLs(c, userID, count, enteApp)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"urls": urls,
	})
}

// CreateFile create a new file inside the collection corresponding to the public accessToken
func (h *PublicCollectionHandler) CreateFile(c *gin.Context) {
	var file ente.File
	if err := c.ShouldBindJSON(&file); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	enteApp := auth.GetApp(c)

	fileRes, err := h.Controller.CreateFile(c, file, enteApp)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, fileRes)
}

// VerifyPassword verifies the password for given public access token and return signed jwt token if it's valid
func (h *PublicCollectionHandler) VerifyPassword(c *gin.Context) {
	var req ente.VerifyPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	resp, err := h.Controller.VerifyPassword(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, resp)
}

// ReportAbuse captures abuse report for a public collection
func (h *PublicCollectionHandler) ReportAbuse(c *gin.Context) {
	var req ente.AbuseReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	err := h.Controller.ReportAbuse(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// GetDiff returns the diff within a collection since a timestamp
func (h *PublicCollectionHandler) GetDiff(c *gin.Context) {
	sinceTime, err := strconv.ParseInt(c.Query("sinceTime"), 10, 64)
	if err != nil {
		errorMessage := fmt.Sprintf("invalid sinceTime val: %s", c.Query("sinceTime"))
		handler.Error(c, stacktrace.Propagate(ente.NewBadRequestWithMessage(errorMessage), err.Error()))
		return
	}
	files, hasMore, err := h.CollectionCtrl.GetPublicDiff(c, sinceTime)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"diff":    files,
		"hasMore": hasMore,
	})
}

func (h *PublicCollectionHandler) getFileForType(c *gin.Context, objectType ente.ObjectType) {
	fileID, err := strconv.ParseInt(c.Param("fileID"), 10, 64)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
		return
	}
	accessContext := auth.MustGetPublicAccessContext(c)
	url, err := h.FileCtrl.GetPublicOrCastFileURL(c, fileID, objectType, accessContext.CollectionID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Redirect(http.StatusTemporaryRedirect, url)
}
