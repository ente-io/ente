package api

import (
	"context"
	"github.com/go-resty/resty/v2"
)

const (
	EnteAPIEndpoint = "https://api.ente.io"
	TokenHeader     = "X-Auth-Token"
	TokenQuery      = "token"
	ClientPkgHeader = "X-Client-Package"
)

var (
	RedactedHeaders = []string{TokenHeader, " X-Request-Id"}
)
var tokenMap map[string]string = make(map[string]string)

type Client struct {
	restClient *resty.Client
}

type Params struct {
	Debug bool
	Trace bool
	Host  string
}

func readValueFromContext(ctx context.Context, key string) interface{} {
	value := ctx.Value(key)
	return value
}

func NewClient(p Params) *Client {
	enteAPI := resty.New()
	if p.Trace {
		enteAPI.EnableTrace()
	}
	enteAPI.OnBeforeRequest(func(c *resty.Client, req *resty.Request) error {
		app := readValueFromContext(req.Context(), "app")
		if app == nil {
			panic("app not set in context")
		}
		req.Header.Set(ClientPkgHeader, StringToApp(app.(string)).ClientPkg())
		accountId := readValueFromContext(req.Context(), "account_id")
		if accountId != nil && accountId != "" {
			if token, ok := tokenMap[accountId.(string)]; ok {
				req.SetHeader(TokenHeader, token)
			}
		}
		return nil
	})
	if p.Debug {
		enteAPI.OnBeforeRequest(func(c *resty.Client, req *resty.Request) error {
			logRequest(req)
			return nil
		})

		enteAPI.OnAfterResponse(func(c *resty.Client, resp *resty.Response) error {
			logResponse(resp)
			return nil
		})
	}
	if p.Host != "" {
		enteAPI.SetBaseURL(p.Host)
	} else {
		enteAPI.SetBaseURL(EnteAPIEndpoint)
	}
	return &Client{
		restClient: enteAPI,
	}
}

func (c *Client) AddToken(id string, token string) {
	tokenMap[id] = token
}
