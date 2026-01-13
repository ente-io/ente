package uploader

import (
	"bytes"
	"context"
	rand "crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"image"
	"image/jpeg"
	_ "image/png"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"golang.org/x/crypto/nacl/secretbox"

	"github.com/ente-io/cli/internal/api"
	"github.com/ente-io/cli/internal/crypto"
)

// SimpleFileMetadata represents the metadata for a file being uploaded
type SimpleFileMetadata struct {
	FileType         int     `json:"fileType"`
	Title            string  `json:"title"`
	CreationTime     int64   `json:"creationTime"`
	ModificationTime int64   `json:"modificationTime"`
	Latitude         float64 `json:"latitude,omitempty"`
	Longitude        float64 `json:"longitude,omitempty"`
	Hash             string  `json:"hash,omitempty"`
}

// EncryptedFileData contains the encrypted file components
type EncryptedFileData struct {
	EncryptedData    []byte
	DecryptionHeader []byte
}

// UploadSession holds the context for an upload operation
type UploadSession struct {
	client     *api.Client
	collection *api.Collection
}

// NewUploadSession creates a new upload session
func NewUploadSession(client *api.Client, collection *api.Collection) *UploadSession {
	return &UploadSession{
		client:     client,
		collection: collection,
	}
}

// EncryptFileData encrypts file data using the collection key
func (us *UploadSession) EncryptFileData(data []byte, collectionKey []byte) (*EncryptedFileData, error) {
	encryptedData, header, err := crypto.EncryptChaCha20poly1305(data, collectionKey)
	if err != nil {
		return nil, fmt.Errorf("failed to encrypt data: %w", err)
	}

	return &EncryptedFileData{
		EncryptedData:    encryptedData,
		DecryptionHeader: header,
	}, nil
}

// EncryptMetadata encrypts file metadata
func (us *UploadSession) EncryptMetadata(metadata *SimpleFileMetadata, fileKey []byte) (*EncryptedFileData, error) {
	metadataJSON, err := json.Marshal(metadata)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal metadata: %w", err)
	}

	return us.EncryptFileData(metadataJSON, fileKey)
}

// DecryptMetadata decrypts encrypted file metadata
func (us *UploadSession) DecryptMetadata(encData, header []byte, fileKey []byte) (*SimpleFileMetadata, error) {
	decryptor, err := crypto.NewDecryptor(fileKey, header)
	if err != nil {
		return nil, err
	}
	decryptedJSON, tag, err := decryptor.Pull(encData)
	if err != nil {
		return nil, err
	}
	if tag != crypto.TagFinal {
		return nil, fmt.Errorf("invalid tag: %v", tag)
	}

	var metadata SimpleFileMetadata
	if err := json.Unmarshal(decryptedJSON, &metadata); err != nil {
		return nil, err
	}
	return &metadata, nil
}

// DecryptFileKey decrypts a file key using the collection key
func (us *UploadSession) DecryptFileKey(encryptedKey, nonce, collectionKey []byte) ([]byte, error) {
	return crypto.SecretBoxOpen(encryptedKey, nonce, collectionKey)
}

// ReadAndEncryptFile reads a file from disk and encrypts it using chunked encryption
// Chunked encryption is required for web client compatibility with large files
func (us *UploadSession) ReadAndEncryptFile(filePath string, collectionKey []byte) (*EncryptedFileData, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	// Read file data
	data, err := io.ReadAll(file)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	// Use chunked encryption for web client compatibility
	encryptedData, header, err := crypto.EncryptChaCha20poly1305Chunked(data, collectionKey)
	if err != nil {
		return nil, fmt.Errorf("failed to encrypt data: %w", err)
	}

	return &EncryptedFileData{
		EncryptedData:    encryptedData,
		DecryptionHeader: header,
	}, nil
}

// GenerateThumbnail creates a thumbnail for the image/video file
func (us *UploadSession) GenerateThumbnail(filePath string, key []byte) (*EncryptedFileData, error) {
	// Try to generate thumbnail using external tools first
	thumbData, err := generateThumbnailExternal(filePath)
	if err == nil && len(thumbData) > 0 {
		return us.EncryptFileData(thumbData, key)
	}

	// Fallback to internal image decode/resize
	file, err := os.Open(filePath)
	if err == nil {
		defer file.Close()
		img, _, err := image.Decode(file)
		if err == nil {
			thumbImg := resizeImage(img, 512, 512)
			var buf bytes.Buffer
			if err := jpeg.Encode(&buf, thumbImg, &jpeg.Options{Quality: 80}); err == nil {
				return us.EncryptFileData(buf.Bytes(), key)
			}
		}
	}

	// Final fallback: Placeholder thumbnail (appears as gray square)
	thumbData = generatePlaceholderJPEG()
	return us.EncryptFileData(thumbData, key)
}

func generateThumbnailExternal(filePath string) ([]byte, error) {
	// 1. Try sips on macOS (handles HEIC, JPG, PNG, etc)
	if _, err := exec.LookPath("sips"); err == nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		outPath := filepath.Join(os.TempDir(), "thumb_"+filepath.Base(filePath)+".jpg")
		// sips -s format jpeg -s formatOptions 70 -Z 512 input --out output
		cmd := exec.CommandContext(ctx, "sips", "-s", "format", "jpeg", "-s", "formatOptions", "70", "-Z", "512", filePath, "--out", outPath)
		if err := cmd.Run(); err == nil {
			defer os.Remove(outPath)
			return os.ReadFile(outPath)
		}
	}

	// 2. Try ffmpeg (handles Video, Motion Photos)
	if _, err := exec.LookPath("ffmpeg"); err == nil {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		outPath := filepath.Join(os.TempDir(), "thumb_vid_"+filepath.Base(filePath)+".jpg")

		// ffmpeg -y -i input -ss 00:00:01 -vframes 1 -vf scale=512:-1 -q:v 2 output
		// We use scale=512:-1 to keep aspect ratio
		cmd := exec.CommandContext(ctx, "ffmpeg", "-y", "-i", filePath, "-ss", "00:00:00.100", "-vframes", "1", "-vf", "scale='if(gt(iw,ih),512,-1)':'if(gt(iw,ih),-1,512)'", "-q:v", "2", outPath)
		if err := cmd.Run(); err == nil {
			defer os.Remove(outPath)
			return os.ReadFile(outPath)
		}
	}

	return nil, fmt.Errorf("no suitable tool found or command failed")
}

func generatePlaceholderJPEG() []byte {
	// Create a 32x32 gray placeholder
	img := image.NewRGBA(image.Rect(0, 0, 32, 32))
	// Fill with a visible color (e.g., dark gray)
	for i := 0; i < len(img.Pix); i += 4 {
		img.Pix[i] = 50    // R
		img.Pix[i+1] = 50  // G
		img.Pix[i+2] = 50  // B
		img.Pix[i+3] = 255 // A
	}

	var buf bytes.Buffer
	// Encode to JPEG
	jpeg.Encode(&buf, img, &jpeg.Options{Quality: 50})
	return buf.Bytes()
}

func resizeImage(img image.Image, maxWidth, maxHeight int) image.Image {
	bounds := img.Bounds()
	w, h := bounds.Dx(), bounds.Dy()

	if w <= maxWidth && h <= maxHeight {
		return img
	}

	// Calculate target dimensions
	ratio := float64(w) / float64(h)
	targetW, targetH := w, h

	if w > maxWidth {
		targetW = maxWidth
		targetH = int(float64(targetW) / ratio)
	}
	if targetH > maxHeight {
		targetH = maxHeight
		targetW = int(float64(targetH) * ratio)
	}

	// Nearest-neighbor scaling
	dst := image.NewRGBA(image.Rect(0, 0, targetW, targetH))

	xScale := float64(w) / float64(targetW)
	yScale := float64(h) / float64(targetH)

	for y := 0; y < targetH; y++ {
		for x := 0; x < targetW; x++ {
			srcX := int(float64(x) * xScale)
			srcY := int(float64(y) * yScale)
			// Clamp
			if srcX >= w {
				srcX = w - 1
			}
			if srcY >= h {
				srcY = h - 1
			}

			dst.Set(x, y, img.At(bounds.Min.X+srcX, bounds.Min.Y+srcY))
		}
	}
	return dst
}

// GetFileModTime gets the modification time of a file
func GetFileModTime(filePath string) (int64, error) {
	info, err := os.Stat(filePath)
	if err != nil {
		return 0, err
	}
	return info.ModTime().Unix() * 1000000, nil // Convert to microseconds
}

// GetFileName returns the base name of a file
func GetFileName(filePath string) string {
	return filepath.Base(filePath)
}

// EncodeBase64 encodes bytes to base64 string
func EncodeBase64(data []byte) string {
	return base64.StdEncoding.EncodeToString(data)
}

// GenerateFileKey creates a new random encryption key for a file
func GenerateFileKey() ([]byte, error) {
	key := make([]byte, 32)
	if _, err := rand.Read(key); err != nil {
		return nil, fmt.Errorf("failed to generate file key: %w", err)
	}
	return key, nil
}

// EncryptFileKeyWithCollectionKey encrypts a file key using the collection key
func EncryptFileKeyWithCollectionKey(fileKey, collectionKey []byte) (encryptedKey, nonce []byte, err error) {
	// Generate nonce for secretbox
	var nonceArray [24]byte
	if _, err := rand.Read(nonceArray[:]); err != nil {
		return nil, nil, fmt.Errorf("failed to generate nonce: %w", err)
	}

	var keyArray [32]byte
	copy(keyArray[:], collectionKey)

	// Encrypt file key with collection key using secretbox
	encrypted := secretbox.Seal(nil, fileKey, &nonceArray, &keyArray)

	return encrypted, nonceArray[:], nil
}
