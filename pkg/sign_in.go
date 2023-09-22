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

type accSecretInfo struct {
	MasterKey []byte
	SecretKey []byte
	Token     []byte
}

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
		salt := utils.DecodeBase64(srpAttr.SRPSalt)
		clientSecret := srp.GenKey()
		srpClient := srp.NewClient(srpParams, salt, identify, loginKey, clientSecret)
		clientA := srpClient.ComputeA()
		session, err := c.Client.CreateSRPSession(ctx, srpAttr.SRPUserID, utils.EncodeBase64(clientA))
		if err != nil {
			return nil, nil, err
		}
		serverB := session.SRPB
		srpClient.SetB(utils.DecodeBase64(serverB))
		clientM := srpClient.ComputeM1()
		authResp, err := c.Client.VerifySRPSession(ctx, srpAttr.SRPUserID, session.SessionID, utils.EncodeBase64(clientM))
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
) (*accSecretInfo, error) {

	var currentKeyEncKey []byte
	var masterKey, secretKey, tokenKey []byte
	var err error
	for {
		if keyEncKey == nil {
			// CLI prompt for password
			password, flowErr := GetSensitiveField("Enter password")
			if flowErr != nil {
				return nil, flowErr
			}
			fmt.Println("\nPlease wait authenticating...")
			currentKeyEncKey, err = enteCrypto.DeriveArgonKey(password,
				authResp.KeyAttributes.KEKSalt, authResp.KeyAttributes.MemLimit, authResp.KeyAttributes.OpsLimit)
			if err != nil {
				fmt.Printf("error deriving key encryption key: %v", err)
				return nil, err
			}
		} else {
			currentKeyEncKey = keyEncKey
		}

		encryptedKey := utils.DecodeBase64(authResp.KeyAttributes.EncryptedKey)
		encryptedKeyNonce := utils.DecodeBase64(authResp.KeyAttributes.KeyDecryptionNonce)
		key, keyErr := enteCrypto.SecretBoxOpen(encryptedKey, encryptedKeyNonce, currentKeyEncKey)
		if keyErr != nil {
			if keyEncKey != nil {
				fmt.Printf("Failed to get key from keyEncryptionKey %s", keyErr)
				return nil, keyErr
			} else {
				fmt.Printf("Incorrect password, error decrypting master key: %v", keyErr)
				continue
			}
		}
		secretKey, keyErr = enteCrypto.SecretBoxOpen(
			utils.DecodeBase64(authResp.KeyAttributes.EncryptedSecretKey),
			utils.DecodeBase64(authResp.KeyAttributes.SecretKeyDecryptionNonce),
			key,
		)
		if keyErr != nil {
			fmt.Printf("error decrypting master key: %v", keyErr)
			return nil, keyErr
		}
		tokenKey, err = enteCrypto.SealedBoxOpen(
			utils.DecodeBase64(authResp.EncryptedToken),
			utils.DecodeBase64(authResp.KeyAttributes.PublicKey),
			secretKey,
		)
		if err != nil {
			fmt.Printf("error decrypting token: %v", err)
			return nil, err
		}
		break
	}
	return &accSecretInfo{
		MasterKey: masterKey,
		SecretKey: secretKey,
		Token:     tokenKey,
	}, nil
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
