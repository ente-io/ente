package controller

import (
	"fmt"
	"net/url"
	"strings"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/external/listmonk"
	"github.com/ente-io/museum/pkg/external/zoho"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

// ZohoMailingListsController is used to keeping the external mailing lists in sync
// with customer email changes.
//
// ZohoMailingListsController contains methods for keeping external mailing lists in
// sync when new users sign up, or update their email, or delete their account.
// Currently, these mailing lists are hosted on Zoho Campaigns.
//
// See also: Syncing emails with Zoho Campaigns
type ZohoMailingListsController struct {
	zohoAccessToken string
	zohoListKey     string
	zohoTopicIds    string
	zohoCredentials zoho.Credentials
}

// Return a new instance of ZohoMailingListsController
func NewZohoMailingListsController() *ZohoMailingListsController {
	zohoCredentials := zoho.Credentials{
		ClientID:     viper.GetString("zoho.client-id"),
		ClientSecret: viper.GetString("zoho.client-secret"),
		RefreshToken: viper.GetString("zoho.refresh-token"),
	}

	// The Zoho "List Key" identifies a particular list of email IDs that are
	// stored in Zoho. All the actions that we perform (adding, removing and
	// updating emails) are done on this list.
	//
	// https://www.zoho.com/campaigns/help/developers/list-management.html
	zohoListKey := viper.GetString("zoho.list-key")

	// List of topics to which emails are sent.
	//
	// Ostensibly, we can get them from their API
	// https://www.zoho.com/campaigns/oldhelp/api/get-topics.html
	//
	// But that doesn't currently work, luckily we can get these IDs by looking
	// at the HTML source of the topic update dashboard page.
	zohoTopicIds := viper.GetString("zoho.topic-ids")

	// Zoho has a rate limit on the number of access tokens that can created
	// within a given time period. So as an aid in debugging, allow the access
	// token to be passed in. This will not be present in production - there
	// we'll use the refresh token to create an access token on demand.
	zohoAccessToken := viper.GetString("zoho.access_token")

	return &ZohoMailingListsController{
		zohoCredentials: zohoCredentials,
		zohoListKey:     zohoListKey,
		zohoTopicIds:    zohoTopicIds,
		zohoAccessToken: zohoAccessToken,
	}
}

// ListmonkMailingListsController is used to interact with the Listmonk API.
//
// It specifies BaseURL (URL of your listmonk server),
// your listmonk Username and Password
// and ListIDs (an array of integer values indicating the id of listmonk campaign mailing list
// to which the subscriber needs to added)
type ListmonkMailingListsController struct {
	BaseURL  string
	Username string
	Password string
	ListIDs  []int
}

// NewListmonkMailingListsController creates a new instance of ListmonkMailingListsController
// with the API credentials provided in config file
func NewListmonkMailingListsController() *ListmonkMailingListsController {
	credentials := &ListmonkMailingListsController{
		BaseURL:  viper.GetString("listmonk.server-url"),
		Username: viper.GetString("listmonk.username"),
		Password: viper.GetString("listmonk.password"),
		ListIDs:  viper.GetIntSlice("listmonk.list-ids"),
	}
	return credentials
}

// Add the given email address to our default Zoho Campaigns list.
//
// It is valid to resubscribe an email that has previously been unsubscribe.
//
// # Syncing emails with Zoho Campaigns
//
// Zoho Campaigns does not support maintaining a list of raw email addresses
// that can be later updated or deleted via their API. So instead, we maintain
// the email addresses of our customers in a Zoho Campaign "list", and subscribe
// or unsubscribe them to this list.
func (c *ZohoMailingListsController) Subscribe(email string) error {
	if c.shouldSkipZoho() {
		return stacktrace.Propagate(ente.ErrNotImplemented, "")
	}

	// Need to set "Signup Form Disabled" in the list settings since we use this
	// list to keep track of emails that have already been verified.
	//
	// > You can use this API to add contacts to your mailing lists. For signup
	//   form enabled mailing lists, the contacts will receive a confirmation
	//   email. For signup form disabled lists, contacts will be added without
	//   any confirmations.
	//
	// https://www.zoho.com/campaigns/help/developers/contact-subscribe.html
	return c.doListActionZoho("listsubscribe", email)
}

// Unsubscribe the given email address to our default Zoho Campaigns list.
//
// See: [Note: Syncing emails with Zoho Campaigns]
func (c *ZohoMailingListsController) Unsubscribe(email string) error {
	if c.shouldSkipZoho() {
		return stacktrace.Propagate(ente.ErrNotImplemented, "")
	}

	// https://www.zoho.com/campaigns/help/developers/contact-unsubscribe.html
	return c.doListActionZoho("listunsubscribe", email)
}

// shouldSkipZoho checks if the ZohoMailingListsController should be skipped
// due to missing credentials.
func (c *ZohoMailingListsController) shouldSkipZoho() bool {
	if c.zohoCredentials.RefreshToken == "" {
		log.Info("Skipping Zoho mailing list update because credentials are not configured")
		return true
	}
	return false
}

// Both the listsubscribe and listunsubscribe Zoho Campaigns API endpoints work
// similarly, so use this function to keep the common code.
func (c *ZohoMailingListsController) doListActionZoho(action string, email string) error {
	// Query escape the email so that any pluses get converted to %2B.
	escapedEmail := url.QueryEscape(email)
	contactInfo := fmt.Sprintf("{Contact+Email: \"%s\"}", escapedEmail)
	// Instead of using QueryEscape, use PathEscape. QueryEscape escapes the "+"
	// character, which causes Zoho API to not recognize the parameter.
	escapedContactInfo := url.PathEscape(contactInfo)

	url := fmt.Sprintf(
		"https://campaigns.zoho.com/api/v1.1/json/%s?resfmt=JSON&listkey=%s&contactinfo=%s&topic_id=%s",
		action, c.zohoListKey, escapedContactInfo, c.zohoTopicIds)

	zohoAccessToken, err := zoho.DoRequest("POST", url, c.zohoAccessToken, c.zohoCredentials)
	c.zohoAccessToken = zohoAccessToken

	if err != nil {
		// This is not necessarily an error, and can happen when the customer
		// had earlier unsubscribed from our organization emails in Zoho,
		// selecting the "Erase my data" option. This causes Zoho to remove the
		// customer's entire record from their database.
		//
		// Then later, say if the customer deletes their account from ente, we
		// would try to unsubscribe their email but it wouldn't be present in
		// Zoho, and this API call would've failed.
		//
		// In such a case, Zoho will return the following response:
		//
		//   { code":"2103",
		//     "message":"Contact does not exist.",
		//     "version":"1.1",
		//     "uri":"/api/v1.1/json/listunsubscribe",
		//     "status":"error"}
		//
		// Special case these to reduce the severity level so as to not cause
		// error log spam.
		if strings.Contains(err.Error(), "Contact does not exist") {
			log.Warnf("Zoho - Could not %s '%s': %s", action, email, err)
		} else {
			log.Errorf("Zoho - Could not %s '%s': %s", action, email, err)
		}
	}

	return stacktrace.Propagate(err, "")
}

// Add or subscribe an email to listmonk mailing list
func (c *ListmonkMailingListsController) Subscribe(email string) error {
	if c.shouldSkipListmonk() {
		return stacktrace.Propagate(ente.ErrNotImplemented, "")
	}

	data := map[string]interface{}{
		"email": email,
		"lists": c.ListIDs,
	}

	return listmonk.SendRequest("POST", c.BaseURL+"/api/subscribers", data,
		c.Username, c.Password)
}

// Remove or unsubscribe an email from listmonk mailing list
func (c *ListmonkMailingListsController) Unsubscribe(email string) error {
	if c.shouldSkipListmonk() {
		return stacktrace.Propagate(ente.ErrNotImplemented, "")
	}

	// Listmonk dosen't provide an endpoint for unsubscribing users from a particular list
	// directly via their email
	//
	// Thus, fetching subscriberID through email address,
	// and then calling endpoint to modify subscription in a list
	id, err := listmonk.GetSubscriberID(c.BaseURL+"/api/subscribers", c.Username, c.Password, email)
	if err != nil {
		stacktrace.Propagate(err, "")
	}
	// API endpoint expects an array of subscriber id as paarmeter
	subscriberID := []int{id}

	data := map[string]interface{}{
		"ids":             subscriberID,
		"action":          "unsubscribe",
		"target_list_ids": c.ListIDs,
	}

	return listmonk.SendRequest("PUT", c.BaseURL+"/api/subscribers/lists", data,
		c.Username, c.Password)
}

// shouldSkipListmonk checks if the ListmonkMailingListsController should be skipped
// due to missing credentials.
func (c *ListmonkMailingListsController) shouldSkipListmonk() bool {
	if c.BaseURL == "" || c.Username == "" || c.Password == "" {
		log.Info("Skipping Listmonk mailing list because credentials are not configured")
		return true
	}
	return false
}
