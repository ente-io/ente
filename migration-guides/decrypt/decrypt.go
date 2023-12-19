package crypto

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
)

type Export struct {
	Version         int    `json:"version"`
	KDFParams       KDF    `json:"kdfParams"`
	EncryptedData   string `json:"encryptedData"`
	EncryptionNonce string `json:"encryptionNonce"`
}

type KDF struct {
	MemLimit int    `json:"memLimit"`
	OpsLimit int    `json:"opsLimit"`
	Salt     string `json:"salt"`
}

func resolvePath(path string) (string, error) {
	if path[:2] != "~/" {
		return path, nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return home + path[1:], nil
}

func main() {
	defer func() {
		if err := recover(); err != nil {
			fmt.Println("Error:", err)
		}
	}()

	if len(os.Args) != 4 {
		fmt.Println("Usage: ./decrypt <export_file> <password> <output_file>")
		return
	}

	exportFile, err := resolvePath(os.Args[1])
	if err != nil {
		fmt.Println("Error resolving exportFile path:", err)
		return
	}
	password := os.Args[2]
	outputFile, err := resolvePath(os.Args[3])
	if err != nil {
		fmt.Println("Error resolving outputFile path:", err)
		return
	}

	data, err := os.ReadFile(exportFile)
	if err != nil {
		fmt.Println("Error reading file:", err)
		return
	}

	var export Export
	if err := json.Unmarshal(data, &export); err != nil {
		fmt.Println("Error parsing JSON:", err)
		return
	}

	if export.Version != 1 {
		fmt.Println("Unsupported version")
		return
	}

	encryptedData, err := base64.StdEncoding.DecodeString(export.EncryptedData)
	if err != nil {
		fmt.Println("Error decoding encrypted data:", err)
		return
	}

	nonce, err := base64.StdEncoding.DecodeString(export.EncryptionNonce)
	if err != nil {
		fmt.Println("Error decoding nonce:", err)
		return
	}

	key, err := deriveArgonKey(password, export.KDFParams.Salt, export.KDFParams.MemLimit, export.KDFParams.OpsLimit)
	if err != nil {
		fmt.Println("Error deriving key:", err)
		return
	}

	decryptedData, err := decryptChaCha20poly13052(encryptedData, key, nonce)
	if err != nil {
		fmt.Println("Error decrypting data:", err)
		return
	}

	if err := os.WriteFile(outputFile, decryptedData, 0644); err != nil {
		fmt.Println("Error writing decrypted data to file:", err)
		return
	}

	fmt.Printf("Decrypted data written to %s\n", outputFile)
}
