package listmonk

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/ente-io/stacktrace"
)

// Listmonk credentials to interact with the Listmonk API.
// It specifies BaseURL (url of the running listmonk server,
// Listmonk Username and Password.
// Visit https://listmonk.app/ to learn more about running
// Listmonk locally
type Credentials struct {
	BaseURL  string
	Username string
	Password string
}

// GetSubscriberID returns subscriber id of the provided email address,
// else returns an error if email was not found
func GetSubscriberID(endpoint string, username string, password string, subscriberEmail string) (int, error) {
	// Struct for the received API response.
	// Can define other fields as well that can be
	// extracted from response JSON
	type SubscriberResponse struct {
		Data struct {
			Results []struct {
				ID int `json:"id"`
			} `json:"results"`
		} `json:"data"`
	}

	// Constructing query parameters
	// Escape single quotes to prevent SQL-like injection in Listmonk's query syntax
	sanitizedEmail := strings.ReplaceAll(subscriberEmail, "'", "''")
	queryParams := url.Values{}
	queryParams.Set("query", fmt.Sprintf("subscribers.email = '%s'", sanitizedEmail))

	// Constructing the URL with query parameters
	endpointURL, err := url.Parse(endpoint)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}
	endpointURL.RawQuery = queryParams.Encode()

	req, err := http.NewRequest("GET", endpointURL.String(), nil)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}

	req.SetBasicAuth(username, password)

	// Sending the HTTP request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}
	defer resp.Body.Close()

	// Reading the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}

	// Parsing the JSON response
	var subscriberResp SubscriberResponse
	if err := json.Unmarshal(body, &subscriberResp); err != nil {
		return 0, stacktrace.Propagate(err, "")
	}

	// Checking if there are any subscribers found
	if len(subscriberResp.Data.Results) == 0 {
		return 0, stacktrace.Propagate(err, "")
	}

	// Extracting the ID from the response
	id := subscriberResp.Data.Results[0].ID

	return id, nil
}

// SendRequest sends a request to the specified Listmonk API endpoint
// with the provided method and data
// after authentication with the provided credentials (username, password)
func SendRequest(method string, url string, data interface{}, username string, password string) error {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	client := &http.Client{}
	req, err := http.NewRequest(method, url, bytes.NewBuffer(jsonData))
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	req.SetBasicAuth(username, password)
	req.Header.Set("Content-Type", "application/json")

	// Send request
	resp, err := client.Do(req)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return stacktrace.Propagate(err, "")
	}

	return nil
}
