package passkey

import (
	"github.com/ente-io/museum/ente"
	"github.com/google/uuid"
)

func (r *Repository) getWebAuthnSessionByID(sessionID uuid.UUID) (session *ente.WebAuthnSession, err error) {

	session = &ente.WebAuthnSession{}

	err = r.DB.QueryRow(`
		SELECT
			id,
			challenge,
			user_id,
			allowed_credential_ids,
			expires_at,
			user_verification_requirement,
			extensions,
			created_at
		FROM webauthn_sessions
		WHERE id = $1
	`, sessionID).Scan(
		&session.ID,
		&session.Challenge,
		&session.UserID,
		&session.AllowedCredentialIDs,
		&session.ExpiresAt,
		&session.UserVerificationRequirement,
		&session.Extensions,
		&session.CreatedAt,
	)

	return
}
