package api

import (
	"fmt"
	"net/http"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/embedding"
	"github.com/ente-io/museum/pkg/utils/handler"

	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

type EmbeddingHandler struct {
	Controller *embedding.Controller
}

// InsertOrUpdate handler for inserting or updating embedding
func (h *EmbeddingHandler) InsertOrUpdate(c *gin.Context) {
	var request ente.InsertOrUpdateEmbeddingRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	embedding, err := h.Controller.InsertOrUpdate(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, embedding)
}

// GetDiff handler for getting diff of embedding
func (h *EmbeddingHandler) GetDiff(c *gin.Context) {
	var request ente.GetEmbeddingDiffRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	embeddings, err := h.Controller.GetDiff(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"diff": embeddings,
	})
}

// GetFilesEmbedding returns the embeddings for the files
func (h *EmbeddingHandler) GetFilesEmbedding(c *gin.Context) {
	var request ente.GetFilesEmbeddingRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.GetFilesEmbedding(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, resp)
}

// DeleteAll handler for deleting all embeddings for the user
func (h *EmbeddingHandler) DeleteAll(c *gin.Context) {
	err := h.Controller.DeleteAll(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}
