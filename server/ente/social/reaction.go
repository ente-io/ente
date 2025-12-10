package social

// Reaction represents an encrypted reaction scoped to a collection, file, or comment.
type Reaction struct {
	ID           string  `json:"id"`
	CollectionID int64   `json:"collectionID"`
	FileID       *int64  `json:"fileID,omitempty"`
	CommentID    *string `json:"commentID,omitempty"`
	UserID       int64   `json:"userID"`
	AnonUserID   *string `json:"anonUserID,omitempty"`
	Cipher       string  `json:"cipher,omitempty"`
	Nonce        string  `json:"nonce,omitempty"`
	IsDeleted    bool    `json:"isDeleted"`
	CreatedAt    int64   `json:"createdAt"`
	UpdatedAt    int64   `json:"updatedAt"`
}
