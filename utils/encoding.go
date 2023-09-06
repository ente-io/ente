package utils

import (
	"encoding/base64"
)

func Base64DecodeString(s string) []byte {
	b, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		panic(err)
	}
	return b
}

func BytesToBase64(b []byte) string {
	return base64.StdEncoding.EncodeToString(b)
}
