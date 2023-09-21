package pkg

import (
	"cli-go/internal/api"
	enteCrypto "cli-go/internal/crypto"
	"cli-go/utils"
	"context"
	"fmt"
	"log"

	"github.com/kong/go-srp"
)

func (c *ClICtrl) signInViaPassword(ctx context.Context, email string, srpAttr *api.SRPAttributes) (*api.AuthorizationResponse, []byte, error) {
	for {
		// CLI prompt for password
		password, flowErr := GetSensitiveField("Enter password")
		if flowErr != nil {
			return nil, nil, flowErr
		}
		fmt.Println("\nPlease wait authenticating...")
		keyEncKey, err := enteCrypto.DeriveArgonKey(password, srpAttr.KekSalt, srpAttr.MemLimit, srpAttr.OpsLimit)
		if err != nil {
			fmt.Printf("error deriving key encryption key: %v", err)
			return nil, nil, err
		}
		loginKey := enteCrypto.DeriveLoginKey(keyEncKey)

		srpParams := srp.GetParams(4096)
		identify := []byte(srpAttr.SRPUserID.String())
		salt := utils.Base64DecodeString(srpAttr.SRPSalt)
		clientSecret := srp.GenKey()
		srpClient := srp.NewClient(srpParams, salt, identify, loginKey, clientSecret)
		clientA := srpClient.ComputeA()
		session, err := c.Client.CreateSRPSession(ctx, srpAttr.SRPUserID, utils.BytesToBase64(clientA))
		if err != nil {
			return nil, nil, err
		}
		serverB := session.SRPB
		srpClient.SetB(utils.Base64DecodeString(serverB))
		clientM := srpClient.ComputeM1()
		authResp, err := c.Client.VerifySRPSession(ctx, srpAttr.SRPUserID, session.SessionID, utils.BytesToBase64(clientM))
		if err != nil {
			log.Printf("failed to verify %v", err)
			continue
		}
		return authResp, keyEncKey, nil
	}
}

// Parameters:
//   - keyEncKey: key encryption key is derived from user's password. During SRP based login, this key is already derived.
//     So, we can pass it to avoid asking for password again.
func (c *ClICtrl) decryptMasterKeyAndToken(
	_ context.Context,
	authResp *api.AuthorizationResponse,
	keyEncKey []byte,
) (masterKey, token []byte, err error) {

	var currentKeyEncKey []byte
	for {
		if keyEncKey == nil {
			// CLI prompt for password
			password, flowErr := GetSensitiveField("Enter password")
			if flowErr != nil {
				return nil, nil, flowErr
			}
			fmt.Println("\nPlease wait authenticating...")
			currentKeyEncKey, err = enteCrypto.DeriveArgonKey(password,
				authResp.KeyAttributes.KEKSalt, authResp.KeyAttributes.MemLimit, authResp.KeyAttributes.OpsLimit)
			if err != nil {
				fmt.Printf("error deriving key encryption key: %v", err)
				return nil, nil, err
			}
		} else {
			currentKeyEncKey = keyEncKey
		}

		encryptedKey := utils.Base64DecodeString(authResp.KeyAttributes.EncryptedKey)
		encryptedKeyNonce := utils.Base64DecodeString(authResp.KeyAttributes.KeyDecryptionNonce)
		key, keyErr := enteCrypto.SecretBoxOpen(encryptedKey, encryptedKeyNonce, currentKeyEncKey)
		if keyErr != nil {
			if keyEncKey != nil {
				fmt.Printf("Failed to get key from keyEncryptionKey %s", keyErr)
				return nil, nil, keyErr
			} else {
				fmt.Printf("Incorrect password, error decrypting master key: %v", keyErr)
				continue
			}
		}
		masterKey, keyErr = enteCrypto.SecretBoxOpen(
			utils.Base64DecodeString(authResp.KeyAttributes.EncryptedSecretKey),
			utils.Base64DecodeString(authResp.KeyAttributes.SecretKeyDecryptionNonce),
			key,
		)
		if keyErr != nil {
			fmt.Printf("error decrypting master key: %v", keyErr)
			return nil, nil, keyErr
		}
		token, err = enteCrypto.SealedBoxOpen(
			utils.Base64DecodeString(authResp.EncryptedToken),
			utils.Base64DecodeString(authResp.KeyAttributes.PublicKey),
			masterKey,
		)
		if err != nil {
			fmt.Printf("error decrypting token: %v", err)
			return nil, nil, err
		}
		break
	}
	return masterKey, token, nil
}

func (c *ClICtrl) validateTOTP(ctx context.Context, authResp *api.AuthorizationResponse) (*api.AuthorizationResponse, error) {
	if !authResp.IsMFARequired() {
		return authResp, nil
	}
	for {
		// CLI prompt for TOTP
		totp, flowErr := GetCode("Enter TOTP", 6)
		if flowErr != nil {
			return nil, flowErr
		}
		totpResp, err := c.Client.VerifyTotp(ctx, authResp.TwoFactorSessionID, totp)
		if err != nil {
			log.Printf("failed to verify %v", err)
			continue
		}
		return totpResp, nil
	}
}

func (c *ClICtrl) validateEmail(ctx context.Context, email string) (*api.AuthorizationResponse, error) {
	err := c.Client.SendEmailOTP(ctx, email)
	if err != nil {
		return nil, err
	}
	for {
		// CLI prompt for OTP
		ott, flowErr := GetCode("Enter OTP", 6)
		if flowErr != nil {
			return nil, flowErr
		}
		authResponse, err := c.Client.VerifyEmail(ctx, email, ott)
		if err != nil {
			log.Printf("failed to verify %v", err)
			continue
		}
		return authResponse, nil
	}
}
