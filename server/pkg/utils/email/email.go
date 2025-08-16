// The email package contains functions for directly sending emails.
//
// These functions can be used for directly sending emails to given email
// addresses. This is used for transactional emails, for example OTP requests.
// Currently, we use Zoho Transmail to send out the actual mail.
package email

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"
	"net/smtp"
	"path"
	"strings"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

var knownInvalidEmailErrors = []string{
	"Invalid RCPT TO address provided",
	"Invalid domain name",
}

// Send sends an email
func Send(toEmails []string, fromName string, fromEmail string, subject string, htmlBody string, inlineImages []map[string]interface{}) error {
	smtpHost := viper.GetString("smtp.host")
	if smtpHost != "" {
		return sendViaSMTP(toEmails, fromName, fromEmail, subject, htmlBody, inlineImages)
	} else {
		return sendViaTransmail(toEmails, fromName, fromEmail, subject, htmlBody, inlineImages)
	}
}

func sendViaSMTP(toEmails []string, fromName string, fromEmail string, subject string, htmlBody string, inlineImages []map[string]interface{}) error {
	if len(toEmails) == 0 {
		return ente.ErrBadRequest
	}

	smtpServer := viper.GetString("smtp.host")
	smtpPort := viper.GetString("smtp.port")
	smtpUsername := viper.GetString("smtp.username")
	smtpPassword := viper.GetString("smtp.password")
	smtpEmail := viper.GetString("smtp.email")
	smtpSenderName := viper.GetString("smtp.sender-name")
	smtpEncryption := viper.GetString("smtp.encryption")

	var emailMessage string
	var auth smtp.Auth = nil
	if smtpUsername != "" && smtpPassword != "" {
		auth = smtp.PlainAuth("", smtpUsername, smtpPassword, smtpServer)
	}

	// Construct 'emailAddresses' with comma-separated email addresses
	var emailAddresses string
	for i, email := range toEmails {
		if i != 0 {
			emailAddresses += ","
		}
		emailAddresses += email
	}

	// If a sender email is provided use it instead of the fromEmail.
	if smtpEmail != "" {
		fromEmail = smtpEmail
	}
	// If a sender name is provided use it instead of the fromName.
	if smtpSenderName != "" {
		fromName = smtpSenderName
	}

	header := "From: " + fromName + " <" + fromEmail + ">\n" +
		"To: " + emailAddresses + "\n" +
		"Subject: " + subject + "\n" +
		"MIME-Version: 1.0\n" +
		"Content-Type: multipart/related; boundary=boundary\n\n" +
		"--boundary\n"
	htmlContent := "Content-Type: text/html; charset=us-ascii\n\n" + htmlBody + "\n"

	emailMessage = header + htmlContent

	if inlineImages == nil {
		emailMessage += "--boundary--"
	} else {
		for _, inlineImage := range inlineImages {

			emailMessage += "--boundary\n"
			var mimeType = inlineImage["mime_type"].(string)
			var contentID = inlineImage["cid"].(string)
			var imgBase64Str = inlineImage["content"].(string)

			var image = "Content-Type: " + mimeType + "\n" +
				"Content-Transfer-Encoding: base64\n" +
				"Content-ID: <" + contentID + ">\n" +
				"Content-Disposition: inline\n\n" + imgBase64Str + "\n"

			emailMessage += image
		}
		emailMessage += "--boundary--"
	}

	// Send the email to each recipient
	for _, toEmail := range toEmails {
		err := sendMailWithEncryption(smtpServer, smtpPort, auth, fromEmail, []string{toEmail}, []byte(emailMessage), smtpEncryption)
		if err != nil {
			errMsg := err.Error()
			for i := range knownInvalidEmailErrors {
				if strings.Contains(errMsg, knownInvalidEmailErrors[i]) {
					return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("Invalid email %s", toEmail)), errMsg)
				}
			}
			return stacktrace.Propagate(err, "")
		}
	}

	return nil
}

// sendMailWithEncryption sends an email with the specified encryption type
// encryption can be one of:
// - "tls" or "ssl": Uses TLS/SSL encryption for the entire connection
// - "" (empty string) or any other value: No encryption
func sendMailWithEncryption(host, port string, auth smtp.Auth, from string, to []string, msg []byte, encryption string) error {
	addr := host + ":" + port

	switch strings.ToLower(encryption) {
	case "tls", "ssl":
		// For TLS/SSL, establish a secure connection directly
		tlsConfig := &tls.Config{
			ServerName: host,
		}
		conn, err := tls.Dial("tcp", addr, tlsConfig)
		if err != nil {
			return stacktrace.Propagate(err, "failed to establish TLS connection")
		}
		defer conn.Close()

		client, err := smtp.NewClient(conn, host)
		if err != nil {
			return stacktrace.Propagate(err, "failed to create SMTP client over TLS")
		}
		defer client.Close()

		return sendWithClient(client, auth, from, to, msg)

	default:
		// No encryption, use standard SendMail
		return smtp.SendMail(addr, auth, from, to, msg)
	}
}

// sendWithClient sends an email using an established SMTP client
func sendWithClient(client *smtp.Client, auth smtp.Auth, from string, to []string, msg []byte) error {
	if auth != nil {
		if err := client.Auth(auth); err != nil {
			return stacktrace.Propagate(err, "authentication failed")
		}
	}

	if err := client.Mail(from); err != nil {
		return stacktrace.Propagate(err, "failed to set sender")
	}

	for _, addr := range to {
		if err := client.Rcpt(addr); err != nil {
			return stacktrace.Propagate(err, "failed to add recipient")
		}
	}

	w, err := client.Data()
	if err != nil {
		return stacktrace.Propagate(err, "failed to create message writer")
	}

	_, err = w.Write(msg)
	if err != nil {
		return stacktrace.Propagate(err, "failed to write message")
	}

	err = w.Close()
	if err != nil {
		return stacktrace.Propagate(err, "failed to close message writer")
	}

	err = client.Quit()
	return stacktrace.Propagate(err, "")
}

func sendViaTransmail(toEmails []string, fromName string, fromEmail string, subject string, htmlBody string, inlineImages []map[string]interface{}) error {
	if len(toEmails) == 0 {
		return ente.ErrBadRequest
	}

	authKey := viper.GetString("transmail.key")
	silent := viper.GetBool("internal.silent")
	if authKey == "" || silent {
		log.Infof("Skipping sending email to %s: %s", toEmails[0], subject)
		return nil
	}

	var to []ente.ToEmailAddress
	for _, toEmail := range toEmails {
		to = append(to, ente.ToEmailAddress{EmailAddress: ente.EmailAddress{Address: toEmail}})
	}
	mail := &ente.Mail{
		BounceAddress: ente.TransmailEndBounceAddress,
		From:          ente.EmailAddress{Address: fromEmail, Name: fromName},
		Subject:       subject,
		Htmlbody:      htmlBody,
		InlineImages:  inlineImages,
	}
	if len(toEmails) == 1 {
		mail.To = to
	} else {
		mail.Bcc = to
	}
	postBody, err := json.Marshal(mail)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	reqBody := bytes.NewBuffer(postBody)
	client := &http.Client{}
	req, err := http.NewRequest("POST", ente.TransmailEndPoint, reqBody)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	req.Header.Set("accept", "application/json")
	req.Header.Set("content-type", "application/json")
	req.Header.Set("authorization", authKey)
	_, err = client.Do(req)
	return stacktrace.Propagate(err, "")
}

func SendTemplatedEmail(to []string, fromName string, fromEmail string, subject string, templateName string, templateData map[string]interface{}, inlineImages []map[string]interface{}) error {
	body, err := getMailBody(templateName, templateData)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	return Send(to, fromName, fromEmail, subject, body, inlineImages)
}

func SendTemplatedEmailV2(to []string, fromName string, fromEmail string, subject string, baseTemplate, templateName string, templateData map[string]interface{}, inlineImages []map[string]interface{}) error {
	body, err := getMailBodyWithBase(baseTemplate, templateName, templateData)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	return Send(to, fromName, fromEmail, subject, body, inlineImages)
}

func GetMaskedEmail(email string) string {
	at := strings.LastIndex(email, "@")
	if at >= 0 {
		username, domain := email[:at], email[at+1:]
		maskedUsername := ""
		for i := 0; i < len(username); i++ {
			maskedUsername += "*"
		}
		return maskedUsername + "@" + domain
	} else {
		// Should ideally never happen, there should always be an @ symbol
		return "[invalid_email]"
	}
}

// getMailBody generates the mail html body from provided template and data
func getMailBody(templateName string, templateData map[string]interface{}) (string, error) {
	htmlbody := new(bytes.Buffer)
	t := template.Must(template.New(templateName).ParseFiles("mail-templates/" + templateName))
	err := t.Execute(htmlbody, templateData)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	return htmlbody.String(), nil
}

// getMailBody generates the mail HTML body from the provided template and data, supporting inheritance
func getMailBodyWithBase(baseTemplateName, templateName string, templateData map[string]interface{}) (string, error) {
	htmlBody := new(bytes.Buffer)

	// Define paths for the base template and the specific template
	baseTemplate := "mail-templates/" + baseTemplateName
	specificTemplate := "mail-templates/" + templateName

	parts := strings.Split(baseTemplate, "/")
	lastPart := parts[len(parts)-1]
	baseTemplateID := strings.TrimSuffix(lastPart, path.Ext(lastPart))

	// Parse the base and specific templates together
	t, err := template.ParseFiles(baseTemplate, specificTemplate)
	if err != nil {
		return "", stacktrace.Propagate(err, "failed to parse templates")
	}

	// Execute the base template with the provided data
	err = t.ExecuteTemplate(htmlBody, baseTemplateID, templateData)
	if err != nil {
		return "", stacktrace.Propagate(err, "failed to execute template")
	}

	return htmlBody.String(), nil
}
