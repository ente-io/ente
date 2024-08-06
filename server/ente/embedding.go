package ente

type Embedding struct {
	FileID             int64  `json:"fileID"`
	Model              string `json:"model"`
	EncryptedEmbedding string `json:"encryptedEmbedding"`
	DecryptionHeader   string `json:"decryptionHeader"`
	UpdatedAt          int64  `json:"updatedAt"`
	Version            *int   `json:"version,omitempty"`
	Size               *int64
}

// IndexedFile ...
type IndexedFile struct {
	FileID    int64 `json:"fileID"`
	UpdatedAt int64 `json:"updatedAt"`
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

type GetIndexedFiles struct {
	Model     Model  `form:"model"`
	SinceTime *int64 `form:"sinceTime" binding:"required"`
	Limit     *int64 `form:"limit"`
}

type GetFilesEmbeddingRequest struct {
	Model   Model   `form:"model" binding:"required"`
	FileIDs []int64 `form:"fileIDs" binding:"required"`
}

type GetFilesEmbeddingResponse struct {
	Embeddings          []Embedding `json:"embeddings"`
	PendingIndexFileIDs []int64     `json:"pendingIndexFileIDs"`
	ErrFileIDs          []int64     `json:"errFileIDs"`
	NoEmbeddingFileIDs  []int64     `json:"noEmbeddingFileIDs"`
}

type Model string

const (
	OnnxClip Model = "onnx-clip"
	GgmlClip Model = "ggml-clip"

	// Derived inference from a file, including metadata are stored as this type
	Derived = "derived"

	// FileMlClipFace is a model for face embeddings, it is used in request validation.
	FileMlClipFace Model = "file-ml-clip-face"
)

type EmbeddingObject struct {
	Version            int    `json:"v"`
	EncryptedEmbedding string `json:"embedding"`
	DecryptionHeader   string `json:"header"`
	Client             string `json:"client"`
}
