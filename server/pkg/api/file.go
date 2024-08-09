package api

import (
	"fmt"
	"github.com/ente-io/museum/pkg/controller/file_copy"
	"github.com/ente-io/museum/pkg/controller/filedata"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	log "github.com/sirupsen/logrus"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/gin-gonic/gin"
)

// FileHandler exposes request handlers for all encrypted file related requests
type FileHandler struct {
	Controller   *controller.FileController
	FileCopyCtrl *file_copy.FileCopyController
	FileDataCtrl *filedata.Controller
}

// DefaultMaxBatchSize is the default maximum API batch size unless specified otherwise
const DefaultMaxBatchSize = 1000
const DefaultCopyBatchSize = 100

// CreateOrUpdate creates an entry for a file
func (f *FileHandler) CreateOrUpdate(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	var file ente.File
	if err := c.ShouldBindJSON(&file); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	file.UpdationTime = time.Microseconds()

	// get an ente.App from the ?app= query parameter with a default of photos
	enteApp := auth.GetApp(c)

	if file.ID == 0 {
		file.OwnerID = userID
		file.IsDeleted = false
		file, err := f.Controller.Create(c, userID, file, c.Request.UserAgent(), enteApp)
		if err != nil {
			handler.Error(c, stacktrace.Propagate(err, ""))
			return
		}
		c.JSON(http.StatusOK, file)
		return
	}
	response, err := f.Controller.Update(c, userID, file, enteApp)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, response)
}

// CopyFiles copies files that are owned by another user
func (f *FileHandler) CopyFiles(c *gin.Context) {
	var req ente.CopyFileSyncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if len(req.CollectionFileItems) > DefaultCopyBatchSize {
		handler.Error(c, stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("more than %d items", DefaultCopyBatchSize)), ""))
		return
	}
	response, err := f.FileCopyCtrl.CopyFiles(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, response)
}

// Update updates already existing file
func (f *FileHandler) Update(c *gin.Context) {
	enteApp := auth.GetApp(c)

	userID := auth.GetUserID(c.Request.Header)
	var file ente.File
	if err := c.ShouldBindJSON(&file); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	file.UpdationTime = time.Microseconds()
	if file.ID <= 0 {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "fileID should be >0"))
		return
	}
	response, err := f.Controller.Update(c, userID, file, enteApp)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, response)
}

// GetUploadURLs returns a bunch of urls where in the user can upload objects
func (f *FileHandler) GetUploadURLs(c *gin.Context) {
	enteApp := auth.GetApp(c)

	userID := auth.GetUserID(c.Request.Header)
	count, _ := strconv.Atoi(c.Query("count"))
	urls, err := f.Controller.GetUploadURLs(c, userID, count, enteApp, false)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"urls": urls,
	})
}

// GetMultipartUploadURLs returns an array of PartUpload PresignedURLs
func (f *FileHandler) GetMultipartUploadURLs(c *gin.Context) {
	enteApp := auth.GetApp(c)

	userID := auth.GetUserID(c.Request.Header)
	count, _ := strconv.Atoi(c.Query("count"))
	urls, err := f.Controller.GetMultipartUploadURLs(c, userID, count, enteApp)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"urls": urls,
	})
}

// Get redirects the request to the file location
func (f *FileHandler) Get(c *gin.Context) {
	userID, fileID := getUserAndFileIDs(c)
	url, err := f.Controller.GetFileURL(c, userID, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	f.logBadRedirect(c)
	c.Redirect(http.StatusTemporaryRedirect, url)
}

// GetV2 returns the URL of the file to client
func (f *FileHandler) GetV2(c *gin.Context) {
	userID, fileID := getUserAndFileIDs(c)
	url, err := f.Controller.GetFileURL(c, userID, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}

// GetThumbnail redirects the request to the file's thumbnail location
func (f *FileHandler) GetThumbnail(c *gin.Context) {
	userID, fileID := getUserAndFileIDs(c)
	url, err := f.Controller.GetThumbnailURL(c, userID, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	f.logBadRedirect(c)
	c.Redirect(http.StatusTemporaryRedirect, url)
}

// GetThumbnailV2 returns the URL of the thumbnail to the client
func (f *FileHandler) GetThumbnailV2(c *gin.Context) {
	userID, fileID := getUserAndFileIDs(c)
	url, err := f.Controller.GetThumbnailURL(c, userID, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}

// Trash moves the given files to the trash bin
func (f *FileHandler) Trash(c *gin.Context) {
	var request ente.TrashRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to bind"))
		return
	}
	if len(request.TrashItems) > DefaultMaxBatchSize {
		handler.Error(c, stacktrace.Propagate(ente.ErrBatchSizeTooLarge, ""))
		return
	}
	userID := auth.GetUserID(c.Request.Header)
	request.OwnerID = userID
	err := f.Controller.Trash(c, userID, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
	} else {
		c.Status(http.StatusOK)
	}
}

// GetSize returns the size of files indicated by fileIDs
func (f *FileHandler) GetSize(c *gin.Context) {
	var request ente.FileIDsRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	userID := auth.GetUserID(c.Request.Header)
	shouldReject, err := shouldRejectRequest(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if shouldReject {
		c.Status(http.StatusUpgradeRequired)
		return
	}

	size, err := f.Controller.GetSize(userID, request.FileIDs)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
	} else {
		c.JSON(http.StatusOK, gin.H{
			"size": size,
		})
	}
}

// GetInfo returns the FileInfo of files indicated by fileIDs
func (f *FileHandler) GetInfo(c *gin.Context) {
	var request ente.FileIDsRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to bind request"))
		return
	}
	userID := auth.GetUserID(c.Request.Header)

	response, err := f.Controller.GetFileInfo(c, userID, request.FileIDs)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
	} else {
		c.JSON(http.StatusOK, response)
	}
}

// shouldRejectRequest return true if the client which is making the request
// is Android client with version less than 0.5.36
func shouldRejectRequest(c *gin.Context) (bool, error) {
	userAgent := c.GetHeader("User-Agent")
	clientVersion := c.GetHeader("X-Client-Version")
	clientPkg := c.GetHeader("X-Client-Package")

	if !strings.Contains(strings.ToLower(userAgent), "android") {
		return false, nil
	}

	if clientPkg == "io.ente.photos.fdroid" {
		return false, nil
	}

	versionSplit := strings.Split(clientVersion, ".")

	if len(versionSplit) != 3 {
		return false, nil
	}
	if versionSplit[0] != "0" {
		return false, nil
	}
	minorVersion, err := strconv.Atoi(versionSplit[1])
	if err != nil {
		// avoid reject when parsing fails
		return false, nil
	}
	patchVersion, err := strconv.Atoi(versionSplit[2])
	if err != nil {
		// avoid reject when parsing fails
		return false, nil
	}
	shouldReject := minorVersion <= 5 && patchVersion <= 35
	if shouldReject {
		log.Warnf("request rejected from older client with version %s", clientVersion)
	}
	return shouldReject, nil
}

// GetDuplicates returns the list of files of the same size
func (f *FileHandler) GetDuplicates(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	dupes, err := f.Controller.GetDuplicates(userID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"duplicates": dupes,
	})
}

// GetLargeThumbnail returns the list of files whose thumbnail size is larger than threshold size
func (f *FileHandler) GetLargeThumbnailFiles(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	threshold, _ := strconv.ParseInt(c.Query("threshold"), 10, 64)
	largeThumbnailFiles, err := f.Controller.GetLargeThumbnailFiles(userID, threshold)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"largeThumbnailFiles": largeThumbnailFiles,
	})
}

// UpdateMagicMetadata updates magic metadata for a list of files.
func (f *FileHandler) UpdateMagicMetadata(c *gin.Context) {
	var request ente.UpdateMultipleMagicMetadataRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if len(request.MetadataList) > DefaultMaxBatchSize {
		handler.Error(c, stacktrace.Propagate(ente.ErrBatchSizeTooLarge, ""))
		return
	}
	err := f.Controller.UpdateMagicMetadata(c, request, false)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// UpdatePublicMagicMetadata updates public magic metadata for a list of files.
func (f *FileHandler) UpdatePublicMagicMetadata(c *gin.Context) {
	var request ente.UpdateMultipleMagicMetadataRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	err := f.Controller.UpdateMagicMetadata(c, request, true)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

// UpdateThumbnail updates thumbnail of a file
func (f *FileHandler) UpdateThumbnail(c *gin.Context) {
	enteApp := auth.GetApp(c)

	var request ente.UpdateThumbnailRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	err := f.Controller.UpdateThumbnail(c, request.FileID, request.Thumbnail, enteApp)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

func (f *FileHandler) GetTotalFileCount(c *gin.Context) {
	count, err := f.Controller.GetTotalFileCount()
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"count": count,
	})
}

func getUserAndFileIDs(c *gin.Context) (int64, int64) {
	fileID, _ := strconv.ParseInt(c.Param("fileID"), 10, 64)
	userID := auth.GetUserID(c.Request.Header)
	return userID, fileID
}

// logBadRedirect will log the request id if we are redirecting to another url with the auth-token in header
func (f *FileHandler) logBadRedirect(c *gin.Context) {
	if len(c.GetHeader("X-Auth-Token")) != 0 && os.Getenv("ENVIRONMENT") != "" {
		log.WithField("req_id", requestid.Get(c)).Error("critical: sending token to another service")
	}
}
