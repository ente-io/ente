package ente

const (
	// TransmailEndPoint is the mailing endpoint of TransMail (now called
	// ZeptoMail), Zoho's transactional email service.
	TransmailEndPoint = "https://api.transmail.com/v1.1/email"
	// BounceAddress is the emailAddress to send bounce messages to
	TransmailEndBounceAddress = "bounces@bounce.ente.io"
)

type SendEmailRequest struct {
	To        []string `json:"to" binding:"required"`
	FromName  string   `json:"fromName" binding:"required"`
	FromEmail string   `json:"fromEmail" binding:"required"`
	Subject   string   `json:"subject" binding:"required"`
	Body      string   `json:"body" binding:"required"`
}

type Mail struct {
	BounceAddress string                   `json:"bounce_address"`
	From          EmailAddress             `json:"from"`
	To            []ToEmailAddress         `json:"to"`
	Bcc           []ToEmailAddress         `json:"bcc"`
	Subject       string                   `json:"subject"`
	Htmlbody      string                   `json:"htmlbody"`
	InlineImages  []map[string]interface{} `json:"inline_images"`
}

type ToEmailAddress struct {
	EmailAddress EmailAddress `json:"email_address"`
}

type EmailAddress struct {
	Address string `json:"address"`
	Name    string `json:"name"`
}
