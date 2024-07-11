package api

import (
	"context"

	"github.com/google/uuid"
)

func (c *Client) GetSRPAttributes(ctx context.Context, email string) (*SRPAttributes, error) {
	var res struct {
		SRPAttributes *SRPAttributes `json:"attributes"`
	}
	r, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetQueryParam("email", email).
		Get("/users/srp/attributes")
	if err != nil {
		return nil, err
	}
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return res.SRPAttributes, err
}

func (c *Client) CreateSRPSession(
	ctx context.Context,
	srpUserID uuid.UUID,
	clientPub string,
) (*CreateSRPSessionResponse, error) {
	var res CreateSRPSessionResponse
	payload := map[string]interface{}{
		"srpUserID": srpUserID.String(),
		"srpA":      clientPub,
	}
	r, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetBody(payload).
		Post("/users/srp/create-session")
	if err != nil {
		return nil, err
	}
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return &res, nil
}

func (c *Client) VerifySRPSession(
	ctx context.Context,
	srpUserID uuid.UUID,
	sessionID uuid.UUID,
	clientM1 string,
) (*AuthorizationResponse, error) {
	var res AuthorizationResponse
	payload := map[string]interface{}{
		"srpUserID": srpUserID.String(),
		"sessionID": sessionID.String(),
		"srpM1":     clientM1,
	}
	r, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetBody(payload).
		Post("/users/srp/verify-session")
	if err != nil {
		return nil, err
	}
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return &res, nil
}

func (c *Client) SendEmailOTP(
	ctx context.Context,
	email string,
) error {
	var res AuthorizationResponse
	payload := map[string]interface{}{
		"email": email,
	}
	r, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetBody(payload).
		Post("/users/ott")
	if err != nil {
		return err
	}
	if r.IsError() {
		return &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return nil
}

func (c *Client) VerifyEmail(
	ctx context.Context,
	email string,
	otp string,
) (*AuthorizationResponse, error) {
	var res AuthorizationResponse
	payload := map[string]interface{}{
		"email": email,
		"ott":   otp,
	}
	r, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetBody(payload).
		Post("/users/verify-email")
	if err != nil {
		return nil, err
	}
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return &res, nil
}

func (c *Client) VerifyTotp(
	ctx context.Context,
	sessionID string,
	otp string,
) (*AuthorizationResponse, error) {
	var res AuthorizationResponse
	payload := map[string]interface{}{
		"sessionID": sessionID,
		"code":      otp,
	}
	r, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetBody(payload).
		Post("/users/two-factor/verify")
	if err != nil {
		return nil, err
	}
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return &res, nil
}

func (c *Client) CheckPasskeyStatus(ctx context.Context,
	sessionID string) (*AuthorizationResponse, error) {
	var res AuthorizationResponse
	r, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		Get("/users/two-factor/passkeys/get-token?sessionID=" + sessionID)
	if err != nil {
		return nil, err
	}
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return &res, nil
}
