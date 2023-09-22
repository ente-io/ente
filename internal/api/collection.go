package api

import "context"

func (c *Client) GetCollections(ctx context.Context, sinceTime int) ([]Collection, error) {
	var res struct {
		Collections []Collection `json:"collections"`
	}
	r, err := c.restClient.R().
		SetContext(ctx).
		SetQueryParam("since", "0").
		SetResult(&res).
		Get("/collections")
	if r.IsError() {
		return nil, &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}

	return res.Collections, err
}
