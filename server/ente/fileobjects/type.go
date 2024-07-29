package fileobjects

import (
	"database/sql/driver"
	"errors"
	"fmt"
)

type Type string

const (
	OriginalFile      Type = "file"
	OriginalThumbnail Type = "thumb"
	PreviewImage      Type = "previewImage"
	PreviewVideo      Type = "previewVideo"
	Derived           Type = "derived"
)

func (ft Type) IsValid() bool {
	switch ft {
	case OriginalFile, OriginalThumbnail, PreviewImage, PreviewVideo, Derived:
		return true
	}
	return false
}

func (ft *Type) Scan(value interface{}) error {
	strValue, ok := value.(string)
	if !ok {
		return errors.New("type should be a string")
	}

	*ft = Type(strValue)
	if !ft.IsValid() {
		return fmt.Errorf("invalid FileType value: %s", strValue)
	}
	return nil
}

func (ft Type) Value() (driver.Value, error) {
	if !ft.IsValid() {
		return nil, fmt.Errorf("invalid FileType value: %s", ft)
	}
	return string(ft), nil
}
