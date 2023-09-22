package utils

import (
	"encoding/base64"
)

func DecodeBase64(s string) []byte {
	b, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		panic(err)
	}
	return b
}

func EncodeBase64(b []byte) string {
	return base64.StdEncoding.EncodeToString(b)
}
