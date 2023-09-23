package pkg

import (
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
)

type KeyHolder struct {
	AccountSecrets map[string]*accSecretInfo
	CollectionKeys map[string][]byte
}

func NewKeyHolder() *KeyHolder {
	return &KeyHolder{
		AccountSecrets: make(map[string]*accSecretInfo),
		CollectionKeys: make(map[string][]byte),
	}
}

func (k *KeyHolder) LoadSecrets(account model.Account, cliKey []byte) (*accSecretInfo, error) {
	tokenKey := account.Token.MustDecrypt(cliKey)
	masterKey := account.MasterKey.MustDecrypt(cliKey)
	secretKey := account.SecretKey.MustDecrypt(cliKey)
	k.AccountSecrets[account.AccountKey()] = &accSecretInfo{
		Token:     tokenKey,
		MasterKey: masterKey,
		SecretKey: secretKey,
		PublicKey: encoding.DecodeBase64(account.PublicKey),
	}
	return k.AccountSecrets[account.AccountKey()], nil
}

func (k *KeyHolder) GetAccountSecretInfo(ctx context.Context) *accSecretInfo {
	accountKey := ctx.Value("account_id").(string)
	return k.AccountSecrets[accountKey]
}
