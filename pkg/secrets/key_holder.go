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
