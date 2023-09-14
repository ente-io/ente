package api

import (
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
	if p.Host != "" {
		c.SetBaseURL(p.Host)
	} else {
		c.SetBaseURL(EnteAPIEndpoint)
	}
	return &Client{
		restClient: c,
	}
}
