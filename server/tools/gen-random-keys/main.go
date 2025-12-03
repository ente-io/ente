package main

import (
	"encoding/base64"
	"fmt"
	"github.com/ente-io/museum/pkg/utils/auth"
	"log"
)

func main() {
	keyLen := 32
	hashByteLen := 64
	keyBytes, err := auth.GenerateRandomBytes(keyLen)
	if err != nil {
		log.Fatal(err)
	}
	key := base64.StdEncoding.EncodeToString(keyBytes)

	hashBytes, err := auth.GenerateRandomBytes(hashByteLen)
	if err != nil {
		log.Fatal(err)
	}
	hash := base64.StdEncoding.EncodeToString(hashBytes)

	jwtBytes, err := auth.GenerateRandomBytes(keyLen)
	if err != nil {
		log.Fatal(err)
	}
	jwt := base64.URLEncoding.EncodeToString(jwtBytes)

	fmt.Printf("key.encryption: %s\n", key)
	fmt.Printf("key.hash: %s\n", hash)
	fmt.Printf("jwt.secret: %s\n", jwt)
}
