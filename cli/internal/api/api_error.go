package api

import (
	"fmt"
	"strings"
)

type ApiError struct {
	Message    string
	StatusCode int
}

func (e *ApiError) Error() string {
	return fmt.Sprintf("status %d with err: %s", e.StatusCode, e.Message)
}

func IsApiError(err error) bool {
	_, ok := err.(*ApiError)
	return ok
}

func IsFileNotInAlbumError(err error) bool {
	if apiErr, ok := err.(*ApiError); ok {
		return strings.Contains(apiErr.Message, "FILE_NOT_FOUND_IN_ALBUM")
	}
	return false
}
