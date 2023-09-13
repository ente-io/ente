package api

import (
	"errors"

	"github.com/go-resty/resty/v2"
)

const (
	EnteAPIEndpoint = "https://api.ente.io"
	TokenHeader     = "X-Auth-Token"
	TokenQuery      = "token"
)

var (
	RedactedHeaders = []string{TokenHeader, " X-Request-Id"}
)

type Client struct {
	restClient *resty.Client
	authToken  *string
}

type Params struct {
	Debug bool
	Trace bool
	Host  string
}

func NewClient(p Params) *Client {
	c := resty.New()
	if p.Trace {
		c.EnableTrace()
	}
	if p.Debug {
		c.OnBeforeRequest(func(c *resty.Client, req *resty.Request) error {
			logRequest(req)
			return nil
		})

		c.OnAfterResponse(func(c *resty.Client, resp *resty.Response) error {
			logResponse(resp)
			return nil
		})
	}
	c.SetError(&Error{})
	if p.Host != "" {
		c.SetBaseURL(p.Host)
	} else {
		c.SetBaseURL(EnteAPIEndpoint)
	}
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
