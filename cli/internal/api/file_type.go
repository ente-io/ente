package api

// File represents an encrypted file in the system
type File struct {
	ID                 int64          `json:"id"`
	OwnerID            int64          `json:"ownerID"`
	CollectionID       int64          `json:"collectionID"`
	CollectionOwnerID  *int64         `json:"collectionOwnerID"`
	EncryptedKey       string         `json:"encryptedKey"`
	KeyDecryptionNonce string         `json:"keyDecryptionNonce"`
	File               FileAttributes `json:"file" binding:"required"`
	Thumbnail          FileAttributes `json:"thumbnail" binding:"required"`
	Metadata           FileAttributes `json:"metadata" binding:"required"`
	IsDeleted          bool           `json:"isDeleted"`
	UpdationTime       int64          `json:"updationTime"`
	MagicMetadata      *MagicMetadata `json:"magicMetadata,omitempty"`
	PubicMagicMetadata *MagicMetadata `json:"pubMagicMetadata,omitempty"`
	Info               *FileInfo      `json:"info,omitempty"`
}

func (f File) IsRemovedFromAlbum() bool {
	return f.IsDeleted || f.File.EncryptedData == "-"
}

// FileInfo has information about storage used by the file & it's metadata(future)
type FileInfo struct {
	FileSize      int64 `json:"fileSize,omitempty"`
	ThumbnailSize int64 `json:"thumbSize,omitempty"`
}

// FileAttributes represents a file item
type FileAttributes struct {
	EncryptedData    string `json:"encryptedData,omitempty"`
	DecryptionHeader string `json:"decryptionHeader" binding:"required"`
}
