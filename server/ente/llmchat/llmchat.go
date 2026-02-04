package llmchat

const ZeroUUID = "00000000-0000-0000-0000-000000000000"

type Key struct {
	UserID       int64  `json:"-"`
	EncryptedKey string `json:"encryptedKey"`
	Header       string `json:"header"`
	CreatedAt    int64  `json:"createdAt"`
	UpdatedAt    int64  `json:"updatedAt"`
}

type AttachmentMeta struct {
	ID             string  `json:"id"`
	Size           int64   `json:"size"`
	ClientMetadata *string `json:"clientMetadata"`
}

type GetAttachmentUploadURLRequest struct {
	ContentLength int64  `json:"contentLength" binding:"required"`
	ContentMD5    string `json:"contentMD5"` // optional, not used for presigning
}

type AttachmentUploadURLResponse struct {
	AttachmentID string `json:"attachmentId"`
	ObjectKey    string `json:"objectKey"`
	URL          string `json:"url"`
}

type Session struct {
	SessionUUID    string  `json:"sessionUUID"`
	UserID         int64   `json:"-"`
	EncryptedData  *string `json:"encryptedData"`
	Header         *string `json:"header"`
	ClientMetadata *string `json:"clientMetadata"`
	IsDeleted      bool    `json:"isDeleted"`
	CreatedAt      int64   `json:"createdAt"`
	UpdatedAt      int64   `json:"updatedAt"`
}

type Message struct {
	MessageUUID       string           `json:"messageUUID"`
	UserID            int64            `json:"-"`
	SessionUUID       string           `json:"sessionUUID"`
	ParentMessageUUID *string          `json:"parentMessageUUID"`
	Sender            string           `json:"sender"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     *string          `json:"encryptedData"`
	Header            *string          `json:"header"`
	ClientMetadata    *string          `json:"clientMetadata"`
	IsDeleted         bool             `json:"isDeleted"`
	CreatedAt         int64            `json:"createdAt"`
	UpdatedAt         int64            `json:"updatedAt"`
}

type UpsertKeyRequest struct {
	EncryptedKey string `json:"encryptedKey" binding:"required"`
	Header       string `json:"header" binding:"required"`
}

type UpsertSessionRequest struct {
	SessionUUID    string  `json:"sessionUUID"`
	EncryptedData  string  `json:"encryptedData" binding:"required"`
	Header         string  `json:"header" binding:"required"`
	ClientMetadata *string `json:"clientMetadata"`
}

type UpsertMessageRequest struct {
	MessageUUID       string           `json:"messageUUID"`
	SessionUUID       string           `json:"sessionUUID"`
	ParentMessageUUID *string          `json:"parentMessageUUID"`
	Sender            string           `json:"sender" binding:"required"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     string           `json:"encryptedData" binding:"required"`
	Header            string           `json:"header" binding:"required"`
	ClientMetadata    *string          `json:"clientMetadata"`
}

type KeyResponse struct {
	EncryptedKey string `json:"encryptedKey"`
	Header       string `json:"header"`
	CreatedAt    int64  `json:"createdAt"`
	UpdatedAt    int64  `json:"updatedAt"`
}

type SessionResponse struct {
	SessionUUID    string  `json:"sessionUUID"`
	EncryptedData  string  `json:"encryptedData"`
	Header         string  `json:"header"`
	ClientMetadata *string `json:"clientMetadata"`
	CreatedAt      int64   `json:"createdAt"`
	UpdatedAt      int64   `json:"updatedAt"`
	IsDeleted      bool    `json:"isDeleted"`
}

type MessageResponse struct {
	MessageUUID       string           `json:"messageUUID"`
	SessionUUID       string           `json:"sessionUUID"`
	ParentMessageUUID *string          `json:"parentMessageUUID"`
	Sender            string           `json:"sender"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     string           `json:"encryptedData"`
	Header            string           `json:"header"`
	ClientMetadata    *string          `json:"clientMetadata"`
	CreatedAt         int64            `json:"createdAt"`
	UpdatedAt         int64            `json:"updatedAt"`
	IsDeleted         bool             `json:"isDeleted"`
}

type DeleteSessionResponse struct {
	SessionUUID string `json:"sessionUUID"`
	DeletedAt   int64  `json:"deletedAt"`
}

type DeleteMessageResponse struct {
	MessageUUID string `json:"messageUUID"`
	DeletedAt   int64  `json:"deletedAt"`
}

type GetDiffRequest struct {
	SinceTime     *int64  `form:"sinceTime" binding:"required"`
	BaseSinceTime *int64  `form:"baseSinceTime"`
	MaxTime       *int64  `form:"maxTime"`
	SinceType     *string `form:"sinceType"`
	SinceID       *string `form:"sinceId"`
	Limit         int16   `form:"limit"`
}

type DiffCursor struct {
	BaseSinceTime int64  `json:"baseSinceTime"`
	SinceTime     int64  `json:"sinceTime"`
	MaxTime       int64  `json:"maxTime"`
	SinceType     string `json:"sinceType"`
	SinceID       string `json:"sinceId"`
}

type SessionDiffEntry struct {
	SessionUUID    string  `json:"sessionUUID"`
	EncryptedData  string  `json:"encryptedData"`
	Header         string  `json:"header"`
	ClientMetadata *string `json:"clientMetadata"`
	CreatedAt      int64   `json:"createdAt"`
	UpdatedAt      int64   `json:"updatedAt"`
}

type MessageDiffEntry struct {
	MessageUUID       string           `json:"messageUUID"`
	SessionUUID       string           `json:"sessionUUID"`
	ParentMessageUUID *string          `json:"parentMessageUUID"`
	Sender            string           `json:"sender"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     string           `json:"encryptedData"`
	Header            string           `json:"header"`
	ClientMetadata    *string          `json:"clientMetadata"`
	CreatedAt         int64            `json:"createdAt"`
	UpdatedAt         int64            `json:"updatedAt"`
}

type SessionTombstone struct {
	SessionUUID string `json:"sessionUUID"`
	DeletedAt   int64  `json:"deletedAt"`
}

type MessageTombstone struct {
	MessageUUID string `json:"messageUUID"`
	DeletedAt   int64  `json:"deletedAt"`
}

type DiffTombstones struct {
	Sessions []SessionTombstone `json:"sessions"`
	Messages []MessageTombstone `json:"messages"`
}

type GetDiffResponse struct {
	Sessions   []SessionDiffEntry `json:"sessions"`
	Messages   []MessageDiffEntry `json:"messages"`
	Tombstones DiffTombstones     `json:"tombstones"`
	Cursor     DiffCursor         `json:"cursor"`
	Timestamp  int64              `json:"timestamp"`
}
