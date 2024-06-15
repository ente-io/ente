package passkey

import (
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	ente_time "github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/go-webauthn/webauthn/protocol"
	"github.com/google/uuid"
	"github.com/spf13/viper"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/byteMarshaller"
	"github.com/go-webauthn/webauthn/webauthn"
)

const (
	// MaxSessionTokenFetchLimit specifies the maximum number of requests a client can make to retrieve token data for a given session ID.
	MaxSessionTokenFetchLimit = 2
	// TokenFetchAllowedDurationInMin is the duration in minutes for which the token fetch is allowed after the session is verified.
	TokenFetchAllowedDurationInMin = 2
)

type Repository struct {
	DB               *sql.DB
	webAuthnInstance *webauthn.WebAuthn
}

type PasskeyUser struct {
	*ente.User
	repo *Repository
}

func (u *PasskeyUser) WebAuthnID() []byte {
	b, _ := byteMarshaller.ConvertInt64ToByte(u.ID)
	return b
}

func (u *PasskeyUser) WebAuthnName() string {
	return u.Email
}

func (u *PasskeyUser) WebAuthnDisplayName() string {
	return u.Name
}

func (u *PasskeyUser) WebAuthnCredentials() []webauthn.Credential {
	creds, err := u.repo.GetUserPasskeyCredentials(u.ID)
	if err != nil {
		return []webauthn.Credential{}
	}

	return creds
}

func (u *PasskeyUser) WebAuthnIcon() string {
	// this specification is deprecated but the interface requires it
	return ""
}

func NewRepository(
	db *sql.DB,
) (repo *Repository, err error) {
	rpId := viper.GetString("webauthn.rpid")
	rpOrigins := viper.GetStringSlice("webauthn.rporigins")

	wconfig := &webauthn.Config{
		RPDisplayName: "Ente",
		RPID:          rpId,
		RPOrigins:     rpOrigins,
		Timeouts: webauthn.TimeoutsConfig{
			Login: webauthn.TimeoutConfig{
				Enforce: true,
				Timeout: time.Duration(2) * time.Minute,
			},
			Registration: webauthn.TimeoutConfig{
				Enforce: true,
				Timeout: time.Duration(5) * time.Minute,
			},
		},
	}

	webAuthnInstance, err := webauthn.New(wconfig)
	if err != nil {
		return
	}

	repo = &Repository{
		DB:               db,
		webAuthnInstance: webAuthnInstance,
	}

	return
}

func (r *Repository) GetUserPasskeys(userID int64) (passkeys []ente.Passkey, err error) {
	rows, err := r.DB.Query(`
		SELECT id, user_id, friendly_name, created_at
		FROM passkeys
		WHERE user_id = $1 AND deleted_at IS NULL
	`, userID)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}
	defer rows.Close()

	for rows.Next() {
		var passkey ente.Passkey
		if err = rows.Scan(
			&passkey.ID,
			&passkey.UserID,
			&passkey.FriendlyName,
			&passkey.CreatedAt,
		); err != nil {
			err = stacktrace.Propagate(err, "")
			return
		}

		passkeys = append(passkeys, passkey)
	}

	return
}

func (r *Repository) CreateBeginRegistrationData(user *ente.User) (options *protocol.CredentialCreation, session *webauthn.SessionData, id uuid.UUID, err error) {
	passkeyUser := &PasskeyUser{
		User: user,
		repo: r,
	}

	if len(passkeyUser.WebAuthnCredentials()) >= ente.MaxPasskeys {
		err = stacktrace.NewError(ente.ErrMaxPasskeysReached.Error())
		return
	}

	options, session, err = r.webAuthnInstance.BeginRegistration(passkeyUser)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	// save session data
	marshalledSessionData, err := r.marshalSessionDataToWebAuthnSession(session)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	id = uuid.New()

	err = r.saveSessionData(id, marshalledSessionData)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	return
}

func (r *Repository) AddPasskeyTwoFactorSession(userID int64, sessionID string, expirationTime int64) error {
	_, err := r.DB.Exec(`INSERT INTO passkey_login_sessions(user_id, session_id, creation_time, expiration_time) VALUES($1, $2, $3, $4)`,
		userID, sessionID, ente_time.Microseconds(), expirationTime)
	return stacktrace.Propagate(err, "")
}

func (r *Repository) GetUserIDWithPasskeyTwoFactorSession(sessionID string) (userID int64, err error) {
	err = r.DB.QueryRow(`SELECT user_id FROM passkey_login_sessions WHERE session_id = $1`, sessionID).Scan(&userID)
	return
}

// IsSessionAlreadyClaimed checks if the both token_data and verified_at are not null for a given session ID
func (r *Repository) IsSessionAlreadyClaimed(sessionID string) (bool, error) {
	var verifiedAt sql.NullInt64
	err := r.DB.QueryRow(`SELECT verified_at FROM passkey_login_sessions WHERE session_id = $1`, sessionID).Scan(&verifiedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, nil
		}
		return false, stacktrace.Propagate(err, "")
	}
	return verifiedAt.Valid, nil
}

// StoreTokenData takes a sessionID, and tokenData, and updates the tokenData in the database
func (r *Repository) StoreTokenData(sessionID string, tokenData ente.TwoFactorAuthorizationResponse) error {
	tokenDataJson, err := json.Marshal(tokenData)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	_, err = r.DB.Exec(`UPDATE passkey_login_sessions SET token_data = $1, verified_at = now_utc_micro_seconds() WHERE session_id = $2`, tokenDataJson, sessionID)
	return stacktrace.Propagate(err, "")
}

// GetTokenData retrieves the token data associated with a given session ID.
// The function will return the token data if the following conditions are met:
// - The token data is not null.
// - The session was verified less than 5 minutes ago.
// - The token fetch count is less than 2.
// If these conditions are met, the function will also increment the token fetch count by 1.
//
// Parameters:
// - sessionID: The ID of the session for which to retrieve the token data.
//
// Returns:
// - A pointer to a TwoFactorAuthorizationResponse object containing the token data, if the conditions are met.
// - An error, if an error occurred while retrieving the token data or if the conditions are not met.
func (r *Repository) GetTokenData(sessionID string) (*ente.TwoFactorAuthorizationResponse, error) {
	var tokenDataJson []byte
	var verifiedAt sql.NullInt64
	var fetchCount int
	err := r.DB.QueryRow(`SELECT token_data, verified_at, token_fetch_cnt FROM passkey_login_sessions WHERE session_id = $1`, sessionID).Scan(&tokenDataJson, &verifiedAt, &fetchCount)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ente.ErrNotFound
		}
		return nil, stacktrace.Propagate(err, "")
	}
	if !verifiedAt.Valid {
		return nil, &ente.ApiError{
			Code:           "SESSION_NOT_VERIFIED",
			Message:        "Session is not verified yet",
			HttpStatusCode: http.StatusBadRequest,
		}
	}
	if verifiedAt.Int64 < ente_time.MicrosecondsBeforeMinutes(TokenFetchAllowedDurationInMin) {
		return nil, &ente.ApiError{
			Code:           "INVALID_SESSION",
			Message:        "Session verified but expired now",
			HttpStatusCode: http.StatusGone,
		}
	}
	if fetchCount >= MaxSessionTokenFetchLimit {
		return nil, &ente.ApiError{
			Code:           "INVALID_SESSION",
			Message:        "Token fetch limit reached",
			HttpStatusCode: http.StatusGone,
		}
	}
	var tokenData ente.TwoFactorAuthorizationResponse
	err = json.Unmarshal(tokenDataJson, &tokenData)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	// update the token_fetch_count
	_, err = r.DB.Exec(`UPDATE passkey_login_sessions SET token_fetch_cnt = token_fetch_cnt + 1 WHERE session_id = $1`, sessionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &tokenData, nil
}

func (r *Repository) CreateBeginAuthenticationData(user *ente.User) (options *protocol.CredentialAssertion, session *webauthn.SessionData, id uuid.UUID, err error) {
	passkeyUser := &PasskeyUser{
		User: user,
		repo: r,
	}

	options, session, err = r.webAuthnInstance.BeginLogin(passkeyUser)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	// save session data
	marshalledSessionData, err := r.marshalSessionDataToWebAuthnSession(session)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	id = uuid.New()

	err = r.saveSessionData(id, marshalledSessionData)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	return
}

func (r *Repository) FinishRegistration(user *ente.User, friendlyName string, req *http.Request, sessionID uuid.UUID) (err error) {
	passkeyUser := &PasskeyUser{
		User: user,
		repo: r,
	}

	session, err := r.getWebAuthnSessionByID(sessionID)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	if session.UserID != user.ID {
		err = stacktrace.NewError("session does not belong to user")
		return
	}

	sessionData, err := session.SessionData()
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	if time.Now().After(sessionData.Expires) {
		err = stacktrace.NewError("session expired")
		return
	}

	credential, err := r.webAuthnInstance.FinishRegistration(passkeyUser, *sessionData, req)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	newPasskey, err := r.createPasskey(user.ID, friendlyName)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	passkeyCredential, err := r.marshalCredentialToPasskeyCredential(credential, newPasskey.ID)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	err = r.createPasskeyCredential(passkeyCredential)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	return
}

func (r *Repository) FinishAuthentication(user *ente.User, req *http.Request, sessionID uuid.UUID) (err error) {
	passkeyUser := &PasskeyUser{
		User: user,
		repo: r,
	}

	session, err := r.getWebAuthnSessionByID(sessionID)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	if session.UserID != user.ID {
		err = stacktrace.NewError("session does not belong to user")
		return
	}

	sessionData, err := session.SessionData()
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	if time.Now().After(sessionData.Expires) {
		err = stacktrace.NewError("session expired")
		return
	}

	_, err = r.webAuthnInstance.FinishLogin(passkeyUser, *sessionData, req)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	return
}

func (r *Repository) DeletePasskey(user *ente.User, passkeyID uuid.UUID) (err error) {
	_, err = r.DB.Exec(`
		UPDATE passkeys
		SET friendly_name = $1,
			deleted_at = $2
		WHERE id = $3 AND user_id = $4 AND deleted_at IS NULL
	`, passkeyID, ente_time.Microseconds(), passkeyID, user.ID)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	return
}

func (r *Repository) RenamePasskey(user *ente.User, passkeyID uuid.UUID, newName string) (err error) {
	_, err = r.DB.Exec(`
		UPDATE passkeys
		SET friendly_name = $1
		WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL
	`, newName, passkeyID, user.ID)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}

	return
}

func (r *Repository) saveSessionData(id uuid.UUID, session *ente.WebAuthnSession) (err error) {
	_, err = r.DB.Exec(`
		INSERT INTO webauthn_sessions (
			id,
			challenge,
			user_id,
			allowed_credential_ids,
			expires_at,
			user_verification_requirement,
			extensions,
			created_at
		) VALUES (
			$1,
			$2,
			$3,
			$4,
			$5,
			$6,
			$7,
			$8
		)
		`,
		id,
		session.Challenge,
		session.UserID,
		session.AllowedCredentialIDs,
		session.ExpiresAt,
		session.UserVerificationRequirement,
		session.Extensions,
		session.CreatedAt,
	)
	return
}

func (r *Repository) marshalCredentialToPasskeyCredential(cred *webauthn.Credential, passkeyID uuid.UUID) (*ente.PasskeyCredential, error) {
	// Convert the PublicKey to base64
	publicKeyB64 := base64.StdEncoding.EncodeToString(cred.PublicKey)

	// Convert the Transports slice to a comma-separated string
	var transports []string
	for _, t := range cred.Transport {
		transports = append(transports, string(t))
	}
	authenticatorTransports := strings.Join(transports, ",")

	// Marshal the Flags to JSON
	credentialFlags, err := json.Marshal(cred.Flags)
	if err != nil {
		return nil, err
	}

	// Marshal the Authenticator to JSON and encode AAGUID to base64
	authenticatorMap := map[string]interface{}{
		"AAGUID":       base64.StdEncoding.EncodeToString(cred.Authenticator.AAGUID),
		"SignCount":    cred.Authenticator.SignCount,
		"CloneWarning": cred.Authenticator.CloneWarning,
		"Attachment":   cred.Authenticator.Attachment,
	}
	authenticatorJSON, err := json.Marshal(authenticatorMap)
	if err != nil {
		return nil, err
	}

	// convert cred.ID into base64
	credID := base64.StdEncoding.EncodeToString(cred.ID)

	// Create the PasskeyCredential
	passkeyCred := &ente.PasskeyCredential{
		CredentialID:            credID,
		PasskeyID:               passkeyID,
		PublicKey:               publicKeyB64,
		AttestationType:         cred.AttestationType,
		AuthenticatorTransports: authenticatorTransports,
		CredentialFlags:         string(credentialFlags),
		Authenticator:           string(authenticatorJSON),
		CreatedAt:               time.Now().UnixMicro(),
	}

	return passkeyCred, nil
}

func (r *Repository) marshalSessionDataToWebAuthnSession(session *webauthn.SessionData) (webAuthnSession *ente.WebAuthnSession, err error) {

	userID, err := byteMarshaller.ConvertBytesToInt64(session.UserID)
	if err != nil {
		return
	}

	extensionsJson, err := json.Marshal(session.Extensions)
	if err != nil {
		return
	}

	newWebAuthnSession := &ente.WebAuthnSession{
		Challenge:                   session.Challenge,
		UserID:                      userID,
		AllowedCredentialIDs:        byteMarshaller.EncodeSlices(session.AllowedCredentialIDs),
		ExpiresAt:                   session.Expires.UnixMicro(),
		UserVerificationRequirement: string(session.UserVerification),
		Extensions:                  string(extensionsJson),
		CreatedAt:                   time.Now().UnixMicro(),
	}

	return newWebAuthnSession, nil
}

func (r *Repository) GetUserPasskeyCredentials(userID int64) (credentials []webauthn.Credential, err error) {
	rows, err := r.DB.Query(`
		SELECT pc.*
		FROM passkey_credentials pc
		JOIN passkeys p ON pc.passkey_id = p.id
		WHERE p.user_id = $1 AND p.deleted_at IS NULL
	`, userID)
	if err != nil {
		err = stacktrace.Propagate(err, "")
		return
	}
	defer rows.Close()

	for rows.Next() {
		var pc ente.PasskeyCredential
		if err = rows.Scan(
			&pc.PasskeyID,
			&pc.CredentialID,
			&pc.PublicKey,
			&pc.AttestationType,
			&pc.AuthenticatorTransports,
			&pc.CredentialFlags,
			&pc.Authenticator,
			&pc.CreatedAt,
		); err != nil {
			err = stacktrace.Propagate(err, "")
			return
		}

		var cred *webauthn.Credential
		cred, err = pc.WebAuthnCredential()
		if err != nil {
			err = stacktrace.Propagate(err, "")
			return
		}

		credentials = append(credentials, *cred)
	}

	return
}

func (repo *Repository) RemoveExpiredPasskeySessions() error {
	_, err := repo.DB.Exec(`DELETE FROM webauthn_sessions WHERE expires_at <= $1`,
		ente_time.Microseconds())
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	_, err = repo.DB.Exec(`DELETE FROM passkey_login_sessions WHERE expiration_time <= $1`,
		ente_time.Microseconds())

	return stacktrace.Propagate(err, "")
}
