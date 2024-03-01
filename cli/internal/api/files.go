package api

import (
	"context"
	"strconv"
)

var (
	downloadHost = "https://files.ente.io/?fileID="
)

func (c *Client) DownloadFile(ctx context.Context, fileID int64, absolutePath string) error {
	req := c.downloadClient.R().
		SetContext(ctx).
		SetOutput(absolutePath)
	attachToken(req)
	r, err := req.Get(downloadHost + strconv.FormatInt(fileID, 10))
	if r.IsError() {
		return &ApiError{
			StatusCode: r.StatusCode(),
			Message:    r.String(),
		}
	}
	return err
}
