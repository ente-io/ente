package ente

type AddWrappedKeyRequest struct {
	WrappedKey       string `json:"wrappedKey" binding:"required"`
	CustomIdentifier string `json:"customIdentifier"`
}
