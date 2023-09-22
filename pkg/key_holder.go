package pkg

import "cli-go/pkg/model"

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
	}
	return k.AccountSecrets[account.AccountKey()], nil
}
