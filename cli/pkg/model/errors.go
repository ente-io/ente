package model

import (
	"errors"
	"strings"
)

var ErrDecryption = errors.New("error while decrypting the file")
var ErrLiveZip = errors.New("error: no image or video file found in zip")

func ShouldRetrySync(err error) bool {
	return strings.Contains(err.Error(), "read tcp") ||
		strings.Contains(err.Error(), "dial tcp")
}
