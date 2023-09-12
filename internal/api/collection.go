package api

import "context"

func (c *Client) GetCollections(ctx context.Context, sinceTime int) ([]Collection, error) {
	var collections []Collection
	_, err := c.restClient.R().
		SetContext(ctx).
		SetQueryParam("since", string(sinceTime)).
		SetResult(&collections).
		Get("/collections")
	return collections, err
}
