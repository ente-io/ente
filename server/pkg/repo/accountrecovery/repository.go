package accountrecovery

import (
	"database/sql"
	"github.com/ente-io/museum/ente"
)

type Repository struct {
	Db *sql.DB
}

// GetAccountRecoveryStatus returns `ente.AccountRecoveryStatus` for a user
func (r *Repository) GetAccountRecoveryStatus(userID int64) (*ente.AccountRecoveryStatus, error) {
	var isAdminResetEnabled bool
	var resetKey sql.NullString
	row := r.Db.QueryRow("SELECT enable_admin_mfa_reset, pass_key_reset_key FROM account_recovery WHERE user_id = $1", userID)
	err := row.Scan(&isAdminResetEnabled, &resetKey)
	if err != nil {
		if err == sql.ErrNoRows {
			// by default, admin
			return &ente.AccountRecoveryStatus{
				AllowAdminReset:       true,
				IsPassKeyResetEnabled: false,
			}, nil
		}
		return nil, err
	}
	return &ente.AccountRecoveryStatus{AllowAdminReset: isAdminResetEnabled, IsPassKeyResetEnabled: resetKey.Valid}, nil
}
