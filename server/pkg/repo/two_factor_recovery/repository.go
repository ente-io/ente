package two_factor_recovery

import (
	"context"
	"database/sql"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
)

type Repository struct {
	Db *sql.DB
}

// GetStatus returns `ente.TwoFactorRecoveryStatus` for a user
func (r *Repository) GetStatus(userID int64) (*ente.TwoFactorRecoveryStatus, error) {
	var isAdminResetEnabled bool
	var resetKey sql.NullString
	row := r.Db.QueryRow("SELECT enable_admin_mfa_reset, pass_key_reset_key FROM two_factor_recovery WHERE user_id = $1", userID)
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

func (r *Repository) ConfigurePassKeyRecovery(ctx context.Context, userID int64, req *ente.ConfigurePassKeySkipRequest) error {
	_, err := r.Db.ExecContext(ctx, `INSERT INTO two_factor_recovery (user_id, pass_key_reset_key, pass_key_reset_enc_data) 
											VALUES ($1, $2,$3) ON CONFLICT (user_id) 
											DO UPDATE SET pass_key_reset_key = $2, pass_key_reset_enc_data = $3`, userID, req.PassKeySkipSecret,
		req.EncPassKeySkipSecret)
	return err
}

func (r *Repository) GetPasskeyResetChallenge(ctx context.Context, userID int64) (*ente.EncData, error) {
	var encData *ente.EncData
	err := r.Db.QueryRowContext(ctx, "SELECT pass_key_reset_enc_data FROM two_factor_recovery WHERE  user_id= $1", userID).Scan(encData)
	if err != nil {
		return nil, err
	}
	return encData, nil
}

// VerifyRecoveryKeyForPassKey checks if the passkey reset key is valid for a user
func (r *Repository) VerifyRecoveryKeyForPassKey(userID int64, passKeyResetKey string) (bool, error) {
	var exists bool
	row := r.Db.QueryRow(`SELECT EXISTS( SELECT 1 FROM two_factor_recovery WHERE user_id = $1 AND pass_key_reset_key = $2)`, userID, passKeyResetKey)
	err := row.Scan(&exists)
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	return exists, nil
}
