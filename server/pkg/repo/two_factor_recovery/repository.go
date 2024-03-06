package two_factor_recovery

import (
	"context"
	"database/sql"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/crypto"
	"github.com/ente-io/stacktrace"
	"github.com/sirupsen/logrus"
)

type Repository struct {
	Db                  *sql.DB
	SecretEncryptionKey []byte
}

// GetStatus returns `ente.TwoFactorRecoveryStatus` for a user
func (r *Repository) GetStatus(userID int64) (*ente.TwoFactorRecoveryStatus, error) {
	var isAdminResetEnabled bool
	var resetKey sql.NullByte
	row := r.Db.QueryRow(`SELECT enable_admin_mfa_reset, server_passkey_secret_data FROM two_factor_recovery WHERE user_id = $1`, userID)
	err := row.Scan(&isAdminResetEnabled, &resetKey)
	if err != nil {
		if err == sql.ErrNoRows {
			// by default, admin
			return &ente.TwoFactorRecoveryStatus{
				AllowAdminReset:      true,
				IsPassKeySkipEnabled: false,
			}, nil
		}
		return nil, err
	}
	return &ente.TwoFactorRecoveryStatus{AllowAdminReset: isAdminResetEnabled, IsPassKeySkipEnabled: resetKey.Valid}, nil
}

func (r *Repository) ConfigurePassKeySkipChallenge(ctx context.Context, userID int64, req *ente.ConfigurePassKeyRecoveryRequest) error {
	serveEncPassKey, encRrr := crypto.Encrypt(req.SkipSecret, r.SecretEncryptionKey)
	if encRrr != nil {
		return stacktrace.Propagate(encRrr, "failed to encrypt passkey secret")
	}
	_, err := r.Db.ExecContext(ctx, `INSERT INTO two_factor_recovery 
    (user_id, server_passkey_secret_data, server_passkey_secret_nonce, user_passkey_secret_data, user_passkey_secret_nonce)) 
	VALUES ($1, $2,$3,$4,$5)  ON CONFLICT (user_id) 
	DO UPDATE SET server_passkey_secret_data = $2, server_passkey_secret_nonce = $3, user_passkey_secret_data=$4,user_passkey_secret_nonce=$5`,
		userID, serveEncPassKey.Cipher, serveEncPassKey.Nonce, req.UserSecretCipher, req.UserSecretNonce)
	return err
}

func (r *Repository) GetPasskeySkipChallenge(ctx context.Context, userID int64) (*ente.PasseKeySkipChallengeResponse, error) {
	var result *ente.PasseKeySkipChallengeResponse
	err := r.Db.QueryRowContext(ctx, "SELECT user_passkey_secret_data, user_passkey_secret_nonce FROM two_factor_recovery WHERE  user_id= $1", userID).Scan(result.UserSecretCipher, result.UserSecretNonce)
	if err != nil {
		return nil, err
	}
	return result, nil
}

// VerifyPasskeySkipSecret checks if the passkey skip secret is valid for a user
func (r *Repository) VerifyPasskeySkipSecret(userID int64, skipSecret string) (bool, error) {
	// get server_passkey_secret_data and server_passkey_secret_nonce for given user id
	var severSecreteData, serverSecretNonce []byte
	row := r.Db.QueryRow(`SELECT server_passkey_secret_data, server_passkey_secret_nonce FROM two_factor_recovery WHERE user_id = $1`, userID)
	err := row.Scan(&severSecreteData, &serverSecretNonce)
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	// decrypt server_passkey_secret_data
	serverSkipSecretKey, decErr := crypto.Decrypt(severSecreteData, serverSecretNonce, r.SecretEncryptionKey)
	if decErr != nil {
		return false, stacktrace.Propagate(decErr, "failed to decrypt passkey reset key")
	}
	if skipSecret != serverSkipSecretKey {
		logrus.Warn("invalid passkey skip secret")
		return false, nil
	}
	return true, nil
}
