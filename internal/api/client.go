package api

import (
	"errors"

	"github.com/go-resty/resty/v2"
)

type Client struct {
	restClient *resty.Client
}

func NewClient() *Client {
	c := resty.New()
	c.EnableTrace()
	c.SetError(&Error{})
	c.SetBaseURL("https://api.ente.io")
	return &Client{
		restClient: c,
	}
}

// Error type for resty.Error{}
type Error struct{}

// Implement Error() method for the error interface
func (e *Error) Error() string {
	return "Error: response status code is not in the 2xx range"
}

// OnAfterResponse Implement OnAfterResponse() method for the resty.Error interface
func (e *Error) OnAfterResponse(resp *resty.Response) error {
	if resp.StatusCode() < 200 || resp.StatusCode() >= 300 {
		return errors.New(e.Error())
	}
	return nil
}
