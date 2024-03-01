package ente

type GetValueRequest struct {
	Key          string  `form:"key" binding:"required"`
	DefaultValue *string `form:"defaultValue"`
}

type GetValueResponse struct {
	Value string `json:"value" binding:"required"`
}

type UpdateKeyValueRequest struct {
	Key   string `json:"key" binding:"required"`
	Value string `json:"value" binding:"required"`
}
