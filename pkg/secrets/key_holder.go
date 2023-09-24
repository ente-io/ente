package secrets

import (
	"cli-go/internal/api"
	enteCrypto "cli-go/internal/crypto"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"fmt"
)

type KeyHolder struct {
	AccountSecrets map[string]*model.AccSecretInfo
	CollectionKeys map[string][]byte
}

func NewKeyHolder() *KeyHolder {
	return &KeyHolder{
		AccountSecrets: make(map[string]*model.AccSecretInfo),
		CollectionKeys: make(map[string][]byte),
	}
}

// LoadSecrets loads the secrets for a given account using the provided CLI key.
// It decrypts the token key, master key, and secret key using the CLI key.
// The decrypted keys and the decoded public key are stored in the AccountSecrets map using the account key as the map key.
// It returns the account secret information or an error if the decryption fails.
func (k *KeyHolder) LoadSecrets(account model.Account, cliKey []byte) (*model.AccSecretInfo, error) {
	tokenKey := account.Token.MustDecrypt(cliKey)
	masterKey := account.MasterKey.MustDecrypt(cliKey)
	secretKey := account.SecretKey.MustDecrypt(cliKey)
	k.AccountSecrets[account.AccountKey()] = &model.AccSecretInfo{
		Token:     tokenKey,
		MasterKey: masterKey,
		SecretKey: secretKey,
		PublicKey: encoding.DecodeBase64(account.PublicKey),
	}
	return k.AccountSecrets[account.AccountKey()], nil
}

func (k *KeyHolder) GetAccountSecretInfo(ctx context.Context) *model.AccSecretInfo {
	accountKey := ctx.Value("account_id").(string)
	return k.AccountSecrets[accountKey]
}

// GetCollectionKey retrieves the key for a given collection.
// It first fetches the account secret information from the context.
// If the collection owner's ID matches the user ID from the context, it decrypts the collection key using the master key.
// If the collection is shared (i.e., the owner's ID does not match the user ID), it decrypts the collection key using the public and secret keys.
// It returns the decrypted collection key or an error if the decryption fails.
func (k *KeyHolder) GetCollectionKey(ctx context.Context, collection api.Collection) ([]byte, error) {
	accSecretInfo := k.GetAccountSecretInfo(ctx)
	userID := ctx.Value("user_id").(int64)
	if collection.Owner.ID == userID {
		collKey, err := enteCrypto.SecretBoxOpen(
			encoding.DecodeBase64(collection.EncryptedKey),
			encoding.DecodeBase64(collection.KeyDecryptionNonce),
			accSecretInfo.MasterKey)
		if err != nil {
			return nil, fmt.Errorf("collection %d key drive failed %s", collection.ID, err)
		}
		return collKey, nil
	} else {
		collKey, err := enteCrypto.SealedBoxOpen(encoding.DecodeBase64(collection.EncryptedKey),
			accSecretInfo.PublicKey, accSecretInfo.SecretKey)
		if err != nil {
			return nil, fmt.Errorf("shared collection %d key drive failed %s", collection.ID, err)
		}
		return collKey, nil
	}
}
