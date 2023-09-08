package api

import (
	"fmt"
	"github.com/go-resty/resty/v2"
	"strings"
)

func logRequest(req *resty.Request) {
	fmt.Println("Request:")
	fmt.Printf("Method: %s\n", req.Method)
	fmt.Printf("URL: %s\n", req.URL)
	fmt.Println("Headers:")
	for k, v := range req.Header {
		redacted := false
		for _, rh := range RedactedHeaders {
			if strings.ToLower(k) == strings.ToLower(rh) {
				redacted = true
				break
			}
		}
		if redacted {
			fmt.Printf("%s: %s\n", k, "REDACTED")
		} else {
			fmt.Printf("%s: %s\n", k, v)
		}
	}
}

func logResponse(resp *resty.Response) {
	fmt.Println("Response:")
	fmt.Printf("Status Code: %d\n", resp.StatusCode())
	fmt.Printf("Protocol: %s\n", resp.Proto())
	fmt.Printf("Time Duration: %s\n", resp.Time())
	fmt.Println("Headers:")
	for k, v := range resp.Header() {
		redacted := false
		for _, rh := range RedactedHeaders {
			if strings.ToLower(k) == strings.ToLower(rh) {
				redacted = true
				break
			}
		}
		if redacted {
			fmt.Printf("%s: %s\n", k, "REDACTED")
		} else {
			fmt.Printf("%s: %s\n", k, v)
		}
	}
}
