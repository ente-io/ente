package pkg

import (
	"errors"
	"fmt"
	"log"
	"os"

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
	_, err := fmt.Scanln(&input)
	if err != nil {
		return "", err
	}
	if input == "" {
		return "", errors.New("input cannot be empty")
	}
	return input, nil
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
