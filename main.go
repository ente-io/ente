package main

import (
	"cli-go/internal/api"
	enteCrypto "cli-go/internal/crypto"
	"cli-go/utils"
	"context"
	"fmt"
	"github.com/kong/go-srp"
	"os"
)

func main() {
	client := api.NewClient()
	ctx := context.Background()
	pass, _ := os.LookupEnv("ENTE_USER_PASSWORD")
	email, _ := os.LookupEnv("ENTE_USER_EMAIL")
	if pass == "" || email == "" {
		fmt.Println("Please set ENTE_USER_PASSWORD and ENTE_USER_EMAIL environment variables")
		return
	}
	srpAttr, err := client.GetSRPAttributes(ctx, email)
	if err != nil {
		fmt.Println(err)
	}

	keyEncKey, err := enteCrypto.DeriveArgonKey(pass, srpAttr.KekSalt, srpAttr.MemLimit, srpAttr.OpsLimit)
	if err != nil {
		fmt.Printf("error deriving key encryption key: %v", err)
		return
	}
	loginKey := enteCrypto.DeriveLoginKey(keyEncKey)

	srpParams := srp.GetParams(4096)
	identify := []byte(srpAttr.SRPUserID.String())
	salt := utils.Base64DecodeString(srpAttr.SRPSalt)
	clientSecret := srp.GenKey()
	srpClient := srp.NewClient(srpParams, salt, identify, loginKey, clientSecret)
	clientA := srpClient.ComputeA()
	session, err := client.CreateSRPSession(ctx, srpAttr.SRPUserID, utils.BytesToBase64(clientA))
	if err != nil {
		return
	}
	serverB := session.SRPB
	srpClient.SetB(utils.Base64DecodeString(serverB))
	clientM := srpClient.ComputeM1()
	authResp, err := client.VerifySRPSession(ctx, srpAttr.SRPUserID, session.SessionID, utils.BytesToBase64(clientM))
	if err != nil {
		fmt.Errorf("error verifying session: %v", err)
		return
	}

	// generate secure random key 32 bit key

	fmt.Println("Hello World " + srpAttr.SRPUserID.String())
	fmt.Println(string(authResp.ID) + "Hello World ")
}
