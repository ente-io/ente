package api

import (
	"fmt"
	"net/http"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/locationtag"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// LocationTagHandler expose request handlers to all location tag requests
type LocationTagHandler struct {
	Controller *locationtag.Controller
}

// Create handler for creating a new location tag
func (h *LocationTagHandler) Create(c *gin.Context) {
	var request ente.LocationTag
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	request.OwnerID = auth.GetUserID(c.Request.Header)
	resp, err := h.Controller.Create(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to create locationTag"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

// Update handler for updating location tag
func (h *LocationTagHandler) Update(c *gin.Context) {
	var request ente.LocationTag
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	request.OwnerID = auth.GetUserID(c.Request.Header)
	resp, err := h.Controller.Update(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to update locationTag"))
		return
	}
	c.JSON(http.StatusOK, gin.H{"locationTag": resp})
}

// Delete handler for deleting location tag
func (h *LocationTagHandler) Delete(c *gin.Context) {
	var request ente.DeleteLocationTagRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	request.OwnerID = auth.GetUserID(c.Request.Header)
	_, err := h.Controller.Delete(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to delete locationTag"))
		return
	}
	c.Status(http.StatusOK)
}

// GetDiff handler for fetching diff of location tag changes
func (h *LocationTagHandler) GetDiff(c *gin.Context) {
	var request ente.GetLocationTagDiffRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	request.OwnerID = auth.GetUserID(c.Request.Header)
	locationTags, err := h.Controller.GetDiff(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to fetch locationTag diff"))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"diff": locationTags,
	})
}
