package ua

import (
	"errors"

	"github.com/slipros/devicedetector"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

func GetDeviceType(ua string) (string, error) {
	dd, dderr := devicedetector.NewDeviceDetector()
	if dderr != nil {
		return "", dderr
	}
	info := dd.Parse(ua)
	if info == nil {
		return "", errors.New("failed to parse user agent")
	}
	if info.Type == "" {
		return "", nil
	}
	titleCaser := cases.Title(language.English)
	return titleCaser.String(info.Type), nil
}
