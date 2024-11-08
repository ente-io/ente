package api

import (
	"net/http"

	"github.com/ente-io/museum/pkg/controller/offer"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/gin-gonic/gin"
)

// OfferHandler expose request handlers to all offer related requests
type OfferHandler struct {
	Controller *offer.OfferController
}

// Deprecated for now
func (h *OfferHandler) GetBlackFridayOffers(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"offers": h.Controller.GetBlackFridayOffers(network.GetClientCountry(c)),
	})
}
