package model

import (
	"errors"
	"strings"
)

var ErrDecryption = errors.New("error while decrypting the file")

func ShouldRetrySync(err error) bool {
	return strings.Contains(err.Error(), "read tcp") ||
		strings.Contains(err.Error(), "dial tcp")
}
