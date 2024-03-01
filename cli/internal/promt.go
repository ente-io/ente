package internal

import (
	"bufio"
	"errors"
	"fmt"
	"github.com/ente-io/cli/internal/api"
	"log"
	"os"
	"strings"

	"golang.org/x/term"
)

func GetSensitiveField(label string) (string, error) {
	fmt.Printf("%s: ", label)
	input, err := term.ReadPassword(int(os.Stdin.Fd()))
	if err != nil {
		return "", err
	}
	return string(input), nil
}

func GetUserInput(label string) (string, error) {
	fmt.Printf("%s: ", label)
	var input string
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	//_, err := fmt.Scanln(&input)
	if err != nil {
		return "", err
	}
	input = strings.TrimSpace(input)
	if input == "" {
		return "", errors.New("input cannot be empty")
	}
	return input, nil
}

func GetAppType() api.App {
	for {
		app, err := GetUserInput("Enter app type (default: photos)")
		if err != nil {
			fmt.Printf("Use default app type: %s\n", api.AppPhotos)
			return api.AppPhotos
		}
		switch app {
		case "photos":
			return api.AppPhotos
		case "auth":
			return api.AppAuth
		case "locker":
			return api.AppLocker
		case "":
			return api.AppPhotos
		default:
			fmt.Println("invalid app type")
			continue
		}
	}
}

func GetCode(promptText string, length int) (string, error) {
	for {
		ott, err := GetUserInput(promptText)
		if err != nil {
			return "", err
		}
		if ott == "" {
			log.Fatal("no OTP entered")
			return "", errors.New("no OTP entered")
		}
		if ott == "c" {
			return "", errors.New("OTP entry cancelled")
		}
		if len(ott) != length {
			fmt.Printf("OTP must be %d digits", length)
			continue
		}
		return ott, nil
	}
}

func GetExportDir() string {
	for {
		exportDir, err := GetUserInput("Enter export directory")
		if err != nil {
			log.Printf("invalid export directory input: %s\n", err)
			return ""
		}
		if exportDir == "" {
			log.Printf("invalid export directory: %s\n", err)
			continue
		}
		exportDir, err = ResolvePath(exportDir)
		if err != nil {
			log.Printf("invalid export directory: %s\n", err)
			continue
		}
		_, err = ValidateDirForWrite(exportDir)
		if err != nil {
			log.Printf("invalid export directory: %s\n", err)
			continue
		}

		return exportDir
	}
}

func ValidateDirForWrite(dir string) (bool, error) {
	// Check if the path exists
	fileInfo, err := os.Stat(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return false, fmt.Errorf("path does not exist: %s", dir)
		}
		return false, err
	}

	// Check if the path is a directory
	if !fileInfo.IsDir() {
		return false, fmt.Errorf("path is not a directory")
	}

	// Check for write permission
	// Check for write permission by creating a temp file
	tempFile, err := os.CreateTemp(dir, "write_test_")
	if err != nil {
		return false, fmt.Errorf("write permission denied: %v", err)
	}

	// Delete temp file
	defer os.Remove(tempFile.Name())
	if err != nil {
		return false, err
	}

	return true, nil
}

func ResolvePath(path string) (string, error) {
	if path[:2] != "~/" {
		return path, nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return home + path[1:], nil
}
