package llmchat

import (
	"context"
	"strings"

	"github.com/ente-io/museum/ente"
)

type InternalUserRepo interface {
	GetUserByIDInternal(id int64) (ente.User, error)
}

type RemoteStoreRepo interface {
	GetValue(ctx context.Context, userID int64, key string) (string, error)
}

func isInternalUser(ctx context.Context, userID int64, userRepo InternalUserRepo, remoteStoreRepo RemoteStoreRepo) bool {
	if userRepo != nil {
		user, err := userRepo.GetUserByIDInternal(userID)
		if err == nil {
			if strings.HasSuffix(strings.ToLower(user.Email), "@ente.io") {
				return true
			}
		}
	}

	if remoteStoreRepo != nil {
		value, err := remoteStoreRepo.GetValue(ctx, userID, string(ente.IsInternalUser))
		if err == nil && value == "true" {
			return true
		}
	}
	return false
}
