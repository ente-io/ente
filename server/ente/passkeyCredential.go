package ente

import (
	"encoding/base64"
	"encoding/json"
	"strings"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"github.com/google/uuid"
)

// PasskeyCredential are the actual WebAuthn credentials we will send back to the user during auth for the browser to check if they have an eligible authenticator.
type PasskeyCredential struct {
	PasskeyID uuid.UUID `json:"passkeyID"`

	CredentialID string `json:"credentialID"` // string

	PublicKey               string `json:"publicKey"` // b64 []byte
	AttestationType         string `json:"attestationType"`
	AuthenticatorTransports string `json:"authenticatorTransports"` // comma-separated slice of strings
	CredentialFlags         string `json:"credentialFlags"`         // json encoded struct
	Authenticator           string `json:"authenticator"`           // json encoded struct with b64 []byte for AAGUID

	CreatedAt int64 `json:"createdAt"`
}

// de-serialization function into a webauthn.Credential
func (c *PasskeyCredential) WebAuthnCredential() (cred *webauthn.Credential, err error) {

	decodedID, err := base64.StdEncoding.DecodeString(c.CredentialID)
	if err != nil {
		return
	}

	cred = &webauthn.Credential{
		ID:              decodedID,
		AttestationType: c.AttestationType,
	}

	transports := []protocol.AuthenticatorTransport{}
	transportStrings := strings.Split(c.AuthenticatorTransports, ",")
	for _, t := range transportStrings {
		transports = append(transports, protocol.AuthenticatorTransport(string(t)))
	}

	cred.Transport = transports

	// decode b64 back to []byte
	publicKeyByte, err := base64.StdEncoding.DecodeString(c.PublicKey)
	if err != nil {
		return
	}

	cred.PublicKey = publicKeyByte

	err = json.Unmarshal(
		[]byte(c.CredentialFlags),
		&cred.Flags,
	)
	if err != nil {
		return
	}

	authenticatorMap := map[string]interface{}{}

	err = json.Unmarshal(
		[]byte(c.Authenticator),
		&authenticatorMap,
	)
	if err != nil {
		return
	}

	// decode the AAGUID base64 back to []byte
	aaguidByte, err := base64.StdEncoding.DecodeString(
		authenticatorMap["AAGUID"].(string),
	)
	if err != nil {
		return
	}

	authenticator := webauthn.Authenticator{
		AAGUID:       aaguidByte,
		SignCount:    uint32(authenticatorMap["SignCount"].(float64)),
		CloneWarning: authenticatorMap["CloneWarning"].(bool),
		Attachment:   protocol.AuthenticatorAttachment(authenticatorMap["Attachment"].(string)),
	}

	cred.Authenticator = authenticator

	return

}
