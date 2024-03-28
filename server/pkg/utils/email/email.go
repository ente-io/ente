// The email package contains functions for directly sending emails.
//
// These functions can be used for directly sending emails to given email
// addresses. This is used for transactional emails, for example OTP requests.
// Currently, we use Zoho Transmail to send out the actual mail.
package email

import (
	"bytes"
	"encoding/json"
	"html/template"
	"net/http"
	"net/smtp"
	"strings"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

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

	var emailMessage string

	// Construct 'emailAddresses' with comma-separated email addresses
	var emailAddresses string
	for i, email := range toEmails {
		if i != 0 {
			emailAddresses += ","
		}
		emailAddresses += email
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
		auth := smtp.PlainAuth("", smtpUsername, smtpPassword, smtpServer)
		err := smtp.SendMail(smtpServer+":"+smtpPort, auth, fromEmail, []string{toEmail}, []byte(emailMessage))
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
	}

	return nil
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
