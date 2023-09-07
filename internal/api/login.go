package api

import (
	"context"
	"fmt"
	"github.com/google/uuid"
)

func (c *Client) GetSRPAttributes(ctx context.Context, email string) (*SRPAttributes, error) {
	var res struct {
		SRPAttributes SRPAttributes `json:"attributes"`
	}
	_, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetQueryParam("email", email).
		Get("/users/srp/attributes")
	if err != nil {
		return nil, err
	}
	return &res.SRPAttributes, err
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
	_, err := c.restClient.R().
		SetContext(ctx).
		SetResult(&res).
		SetBody(payload).
		Post("/users/srp/create-session")
	if err != nil {
		return nil, err
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
	fmt.Sprintf("%+v", r.RawResponse)
	return &res, nil
}
