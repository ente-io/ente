package pkg

import (
	"errors"
	"fmt"
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
