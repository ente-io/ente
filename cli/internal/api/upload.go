package api

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"strconv"
)

// UploadURL represents a pre-signed upload URL from the server
type UploadURL struct {
	URL       string `json:"url"`
	ObjectKey string `json:"objectKey"`
}

// UploadURLsResponse wraps the list of upload URLs
type UploadURLsResponse struct {
	URLS []UploadURL `json:"urls"`
}

// GetUploadURLs fetches pre-signed URLs for uploading files
func (c *Client) GetUploadURLs(ctx context.Context, count int) ([]UploadURL, error) {
	var res UploadURLsResponse
	r, err := c.restClient.R().
		SetContext(ctx).
		SetQueryParam("count", strconv.Itoa(count)).
		SetResult(&res).
		Get("/files/upload-urls")
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return res.URLS, err
}

// UploadToBucket uploads encrypted data to an S3 bucket using a pre-signed URL
func (c *Client) UploadToBucket(ctx context.Context, uploadURL string, data []byte) error {
	// Use the download client which has retry logic
	r, err := c.downloadClient.R().
		SetContext(ctx).
		SetBody(data).
		SetHeader("Content-Type", "application/octet-stream").
		Put(uploadURL)

	if err != nil {
		return fmt.Errorf("failed to upload to bucket: %w", err)
	}

	if r.IsError() {
		return &ApiError{
			StatusCode: r.StatusCode(),
			Message:    fmt.Sprintf("S3 upload failed: %s", r.String()),
		}
	}

	return nil
}

// FileAttributes represents encrypted file attributes
type UploadedFileAttributes struct {
	ObjectKey        string `json:"objectKey"`
	DecryptionHeader string `json:"decryptionHeader"`
	Size             int64  `json:"size,omitempty"`
}

// CreateFileRequest is the request body for creating a file
type CreateFileRequest struct {
	CollectionID       int64                   `json:"collectionID"`
	EncryptedKey       string                  `json:"encryptedKey"`
	KeyDecryptionNonce string                  `json:"keyDecryptionNonce"`
	File               *UploadedFileAttributes `json:"file"`
	Thumbnail          *UploadedFileAttributes `json:"thumbnail"`
	Metadata           *FileAttributes         `json:"metadata"`
	PubMagicMetadata   *MagicMetadata          `json:"pubMagicMetadata,omitempty"`
}

// CreateFile registers an uploaded file with the server
func (c *Client) CreateFile(ctx context.Context, req *CreateFileRequest) (*File, error) {
	var fileResp struct {
		*File
	}

	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	fmt.Printf("DEBUG: CreateFile request JSON:\n%s\n", string(body))
	}

	r, err := c.restClient.R().
		SetContext(ctx).
		SetBody(bytes.NewReader(body)).
		SetHeader("Content-Type", "application/json").
		SetResult(&fileResp).
		Post("/files")

	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}

	return fileResp.File, err
}

// CreateCollectionRequest is the request to create a new collection
type CreateCollectionRequest struct {
	EncryptedKey        string         `json:"encryptedKey"`
	KeyDecryptionNonce  string         `json:"keyDecryptionNonce"`
	EncryptedName       string         `json:"encryptedName"`
	NameDecryptionNonce string         `json:"nameDecryptionNonce"`
	Type                string         `json:"type"`
	MagicMetadata       *MagicMetadata `json:"magicMetadata,omitempty"`
	PublicMagicMetadata *MagicMetadata `json:"pubMagicMetadata,omitempty"`
}

// CreateCollection creates a new collection (album)
func (c *Client) CreateCollection(ctx context.Context, req *CreateCollectionRequest) (*Collection, error) {
	var colResp struct {
		Collection *Collection `json:"collection"`
	}

	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	r, err := c.restClient.R().
		SetContext(ctx).
		SetBody(bytes.NewReader(body)).
		SetHeader("Content-Type", "application/json").
		SetResult(&colResp).
		Post("/collections")

	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}

	return colResp.Collection, err
}
