package api

// Collection represents a collection
type Collection struct {
	ID                  int64            `json:"id"`
	Owner               CollectionUser   `json:"owner"`
	EncryptedKey        string           `json:"encryptedKey" binding:"required"`
	KeyDecryptionNonce  string           `json:"keyDecryptionNonce,omitempty" binding:"required"`
	Name                string           `json:"name"`
	EncryptedName       string           `json:"encryptedName"`
	NameDecryptionNonce string           `json:"nameDecryptionNonce"`
	Type                string           `json:"type" binding:"required"`
	Sharees             []CollectionUser `json:"sharees"`
	UpdationTime        int64            `json:"updationTime"`
	IsDeleted           bool             `json:"isDeleted,omitempty"`
	MagicMetadata       *MagicMetadata   `json:"magicMetadata,omitempty"`
	PublicMagicMetadata *MagicMetadata   `json:"pubMagicMetadata,omitempty"`
	SharedMagicMetadata *MagicMetadata   `json:"sharedMagicMetadata,omitempty"`
	collectionKey       []byte
}

// CollectionUser represents the owner of a collection
type CollectionUser struct {
	ID    int64  `json:"id"`
	Email string `json:"email"`
	// Deprecated
	Name string `json:"name"`
	Role string `json:"role"`
}

type MagicMetadata struct {
	Version int    `json:"version,omitempty" binding:"required"`
	Count   int    `json:"count,omitempty" binding:"required"`
	Data    string `json:"data,omitempty" binding:"required"`
	Header  string `json:"header,omitempty" binding:"required"`
}

// CollectionFileItem represents a file in an AddFilesRequest and MoveFilesRequest
type CollectionFileItem struct {
	ID                 int64  `json:"id" binding:"required"`
	EncryptedKey       string `json:"encryptedKey"  binding:"required"`
	KeyDecryptionNonce string `json:"keyDecryptionNonce"  binding:"required"`
}
