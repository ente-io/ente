package secrets

import (
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
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
