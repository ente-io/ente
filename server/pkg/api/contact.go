package api

import (
	"fmt"
	"net/http"

	"github.com/ente-io/museum/ente"
	contactmodel "github.com/ente-io/museum/ente/contact"
	contactcontroller "github.com/ente-io/museum/pkg/controller/contact"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

type ContactHandler struct {
	Controller *contactcontroller.Controller
}

func (h *ContactHandler) Create(c *gin.Context) {
	var request contactmodel.CreateRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.Create(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to create contact"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *ContactHandler) Get(c *gin.Context) {
	resp, err := h.Controller.Get(c, c.Param("id"))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to fetch contact"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *ContactHandler) GetDiff(c *gin.Context) {
	var request contactmodel.DiffRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("request binding failed %s", err)))
		return
	}
	diff, err := h.Controller.GetDiff(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to fetch contact diff"))
		return
	}
	c.JSON(http.StatusOK, gin.H{"diff": diff})
}

func (h *ContactHandler) Update(c *gin.Context) {
	var request contactmodel.UpdateRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.Update(c, c.Param("id"), request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to update contact"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *ContactHandler) Delete(c *gin.Context) {
	if err := h.Controller.Delete(c, c.Param("id")); err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to delete contact"))
		return
	}
	c.Status(http.StatusOK)
}

func (h *ContactHandler) GetProfilePictureUploadURL(c *gin.Context) {
	var request contactmodel.ProfilePictureUploadURLRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.GetProfilePictureUploadURL(c, c.Param("id"), request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to create profile picture upload url"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *ContactHandler) AttachProfilePicture(c *gin.Context) {
	var request contactmodel.CommitProfilePictureRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.AttachProfilePicture(c, c.Param("id"), request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to attach profile picture"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *ContactHandler) GetProfilePicture(c *gin.Context) {
	resp, err := h.Controller.GetProfilePictureURL(c, c.Param("id"))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to get profile picture url"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *ContactHandler) DeleteProfilePicture(c *gin.Context) {
	resp, err := h.Controller.DeleteProfilePicture(c, c.Param("id"))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to delete profile picture"))
		return
	}
	c.JSON(http.StatusOK, resp)
}
