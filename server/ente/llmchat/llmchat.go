package llmchat

const ZeroUUID = "00000000-0000-0000-0000-000000000000"

type Key struct {
	UserID       int64  `json:"-"`
	EncryptedKey string `json:"encrypted_key"`
	Header       string `json:"header"`
	CreatedAt    int64  `json:"created_at"`
	UpdatedAt    int64  `json:"updated_at"`
}

type AttachmentMeta struct {
	ID            string `json:"id"`
	Size          int64  `json:"size"`
	EncryptedName string `json:"encrypted_name"`
}

type GetAttachmentUploadURLRequest struct {
	ContentLength int64  `json:"content_length" binding:"required"`
	ContentMD5    string `json:"content_md5"` // optional, not used for presigning
}

type AttachmentUploadURLResponse struct {
	ObjectKey string `json:"object_key"`
	URL       string `json:"url"`
}

type Session struct {
	SessionUUID           string  `json:"session_uuid"`
	UserID                int64   `json:"-"`
	RootSessionUUID       string  `json:"root_session_uuid"`
	BranchFromMessageUUID *string `json:"branch_from_message_uuid"`
	EncryptedData         *string `json:"encrypted_data"`
	Header                *string `json:"header"`
	ClientMetadata        *string `json:"clientMetadata"`
	IsDeleted             bool    `json:"is_deleted"`
	CreatedAt             int64   `json:"created_at"`
	UpdatedAt             int64   `json:"updated_at"`
}

type Message struct {
	MessageUUID       string           `json:"message_uuid"`
	UserID            int64            `json:"-"`
	SessionUUID       string           `json:"session_uuid"`
	ParentMessageUUID *string          `json:"parent_message_uuid"`
	Sender            string           `json:"sender"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     *string          `json:"encrypted_data"`
	Header            *string          `json:"header"`
	ClientMetadata    *string          `json:"clientMetadata"`
	IsDeleted         bool             `json:"is_deleted"`
	CreatedAt         int64            `json:"created_at"`
	UpdatedAt         int64            `json:"updated_at"`
}

type UpsertKeyRequest struct {
	EncryptedKey string `json:"encrypted_key" binding:"required"`
	Header       string `json:"header" binding:"required"`
}

type UpsertSessionRequest struct {
	SessionUUID           string  `json:"session_uuid" binding:"required"`
	RootSessionUUID       string  `json:"root_session_uuid"`
	BranchFromMessageUUID *string `json:"branch_from_message_uuid"`
	EncryptedData         string  `json:"encrypted_data" binding:"required"`
	Header                string  `json:"header" binding:"required"`
	ClientMetadata        *string `json:"clientMetadata"`
}

type UpsertMessageRequest struct {
	MessageUUID       string           `json:"message_uuid" binding:"required"`
	SessionUUID       string           `json:"session_uuid" binding:"required"`
	ParentMessageUUID *string          `json:"parent_message_uuid"`
	Sender            string           `json:"sender" binding:"required"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     string           `json:"encrypted_data" binding:"required"`
	Header            string           `json:"header" binding:"required"`
	ClientMetadata    *string          `json:"clientMetadata"`
}

type KeyResponse struct {
	EncryptedKey string `json:"encrypted_key"`
	Header       string `json:"header"`
	CreatedAt    int64  `json:"created_at"`
	UpdatedAt    int64  `json:"updated_at"`
}

type SessionResponse struct {
	SessionUUID           string  `json:"session_uuid"`
	RootSessionUUID       string  `json:"root_session_uuid"`
	BranchFromMessageUUID *string `json:"branch_from_message_uuid"`
	EncryptedData         string  `json:"encrypted_data"`
	Header                string  `json:"header"`
	ClientMetadata        *string `json:"clientMetadata"`
	CreatedAt             int64   `json:"created_at"`
	UpdatedAt             int64   `json:"updated_at"`
	IsDeleted             bool    `json:"is_deleted"`
}

type MessageResponse struct {
	MessageUUID       string           `json:"message_uuid"`
	SessionUUID       string           `json:"session_uuid"`
	ParentMessageUUID *string          `json:"parent_message_uuid"`
	Sender            string           `json:"sender"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     string           `json:"encrypted_data"`
	Header            string           `json:"header"`
	ClientMetadata    *string          `json:"clientMetadata"`
	CreatedAt         int64            `json:"created_at"`
	UpdatedAt         int64            `json:"updated_at"`
	IsDeleted         bool             `json:"is_deleted"`
}

type DeleteSessionResponse struct {
	SessionUUID string `json:"session_uuid"`
	DeletedAt   int64  `json:"deleted_at"`
}

type DeleteMessageResponse struct {
	MessageUUID string `json:"message_uuid"`
	DeletedAt   int64  `json:"deleted_at"`
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
	BaseSinceTime int64  `json:"base_since_time"`
	SinceTime     int64  `json:"since_time"`
	MaxTime       int64  `json:"max_time"`
	SinceType     string `json:"since_type"`
	SinceID       string `json:"since_id"`
}

type SessionDiffEntry struct {
	SessionUUID           string  `json:"session_uuid"`
	RootSessionUUID       string  `json:"root_session_uuid"`
	BranchFromMessageUUID *string `json:"branch_from_message_uuid"`
	EncryptedData         string  `json:"encrypted_data"`
	Header                string  `json:"header"`
	ClientMetadata        *string `json:"clientMetadata"`
	CreatedAt             int64   `json:"created_at"`
	UpdatedAt             int64   `json:"updated_at"`
}

type MessageDiffEntry struct {
	MessageUUID       string           `json:"message_uuid"`
	SessionUUID       string           `json:"session_uuid"`
	ParentMessageUUID *string          `json:"parent_message_uuid"`
	Sender            string           `json:"sender"`
	Attachments       []AttachmentMeta `json:"attachments"`
	EncryptedData     string           `json:"encrypted_data"`
	Header            string           `json:"header"`
	ClientMetadata    *string          `json:"clientMetadata"`
	CreatedAt         int64            `json:"created_at"`
	UpdatedAt         int64            `json:"updated_at"`
}

type SessionTombstone struct {
	SessionUUID string `json:"session_uuid"`
	DeletedAt   int64  `json:"deleted_at"`
}

type MessageTombstone struct {
	MessageUUID string `json:"message_uuid"`
	DeletedAt   int64  `json:"deleted_at"`
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
