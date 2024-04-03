package ente

type Embedding struct {
	FileID             int64  `json:"fileID"`
	Model              string `json:"model"`
	EncryptedEmbedding string `json:"encryptedEmbedding"`
	DecryptionHeader   string `json:"decryptionHeader"`
	UpdatedAt          int64  `json:"updatedAt"`
	Version            *int   `json:"version,omitempty"`
}

type InsertOrUpdateEmbeddingRequest struct {
	FileID             int64  `json:"fileID" binding:"required"`
	Model              string `json:"model" binding:"required"`
	EncryptedEmbedding string `json:"encryptedEmbedding" binding:"required"`
	DecryptionHeader   string `json:"decryptionHeader" binding:"required"`
	Version            *int   `json:"version,omitempty"`
}

type GetEmbeddingDiffRequest struct {
	Model Model `form:"model"`
	// SinceTime *int64. Pointer allows us to pass 0 value otherwise binding fails for zero Value.
	SinceTime *int64 `form:"sinceTime" binding:"required"`
	Limit     int16  `form:"limit" binding:"required"`
}

type GetFilesEmbeddingRequest struct {
	Model   Model   `form:"model" binding:"required"`
	FileIDs []int64 `form:"fileIDs" binding:"required"`
}

type GetFilesEmbeddingResponse struct {
	Embeddings    []Embedding `json:"embeddings"`
	NoDataFileIDs []int64     `json:"noDataFileIDs"`
	ErrFileIDs    []int64     `json:"errFileIDs"`
}

type Model string

const (
	OnnxClip Model = "onnx-clip"
	GgmlClip Model = "ggml-clip"

	// FileMlClipFace is a model for face embeddings, it is used in request validation.
	FileMlClipFace Model = "file-ml-clip-face"
)

type EmbeddingObject struct {
	Version            int    `json:"v"`
	EncryptedEmbedding string `json:"embedding"`
	DecryptionHeader   string `json:"header"`
	Client             string `json:"client"`
}
