package ente

type Embedding struct {
	FileID             int64  `json:"fileID"`
	Model              string `json:"model"`
	EncryptedEmbedding string `json:"encryptedEmbedding"`
	DecryptionHeader   string `json:"decryptionHeader"`
	UpdatedAt          int64  `json:"updatedAt"`
}

type InsertOrUpdateEmbeddingRequest struct {
	FileID             int64  `json:"fileID" binding:"required"`
	Model              string `json:"model" binding:"required"`
	EncryptedEmbedding string `json:"encryptedEmbedding" binding:"required"`
	DecryptionHeader   string `json:"decryptionHeader" binding:"required"`
}

type GetEmbeddingDiffRequest struct {
	Model Model `form:"model"`
	// SinceTime *int64. Pointer allows us to pass 0 value otherwise binding fails for zero Value.
	SinceTime *int64 `form:"sinceTime" binding:"required"`
	Limit     int16  `form:"limit" binding:"required"`
}

type Model string

const (
	OnnxClip Model = "onnx-clip"
	GgmlClip Model = "ggml-clip"
)

type EmbeddingObject struct {
	Version            int    `json:"v"`
	EncryptedEmbedding string `json:"embedding"`
	DecryptionHeader   string `json:"header"`
	Client             string `json:"client"`
}
