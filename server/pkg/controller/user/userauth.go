package user

import (
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"github.com/ente-io/museum/pkg/utils/random"
	"strings"

	"github.com/ente-io/museum/pkg/utils/config"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/gin-contrib/requestid"
	"github.com/spf13/viper"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/crypto"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type HardCodedOTTEmail struct {
	Email string
	Value string
}

type HardCodedOTT struct {
	Emails            []HardCodedOTTEmail
	LocalDomainSuffix string
	LocalDomainValue  string
}

func ReadHardCodedOTTFromConfig() HardCodedOTT {
	emails := make([]HardCodedOTTEmail, 0)
	emailsSlice := viper.GetStringSlice("internal.hardcoded-ott.emails")
	for _, entry := range emailsSlice {
		xs := strings.Split(entry, ",")
		if len(xs) == 2 && xs[0] != "" && xs[1] != "" {
			emails = append(emails, HardCodedOTTEmail{
				Email: xs[0],
				Value: xs[1],
			})
		} else {
			log.Errorf("Ignoring malformed internal.hardcoded-ott.emails entry %s", entry)
		}
	}

	localDomainSuffix := ""
	localDomainValue := ""
	if config.IsLocalEnvironment() {
		localDomainSuffix = viper.GetString("internal.hardcoded-ott.local-domain-suffix")
		localDomainValue = viper.GetString("internal.hardcoded-ott.local-domain-value")
	}

	return HardCodedOTT{
		Emails:            emails,
		LocalDomainSuffix: localDomainSuffix,
		LocalDomainValue:  localDomainValue,
	}
}

func hardcodedOTTForEmail(hardCodedOTT HardCodedOTT, email string) string {
	for _, entry := range hardCodedOTT.Emails {
		if email == entry.Email {
			return entry.Value
		}
	}

	if hardCodedOTT.LocalDomainSuffix != "" && strings.HasSuffix(email, hardCodedOTT.LocalDomainSuffix) {
		return hardCodedOTT.LocalDomainValue
	}

	return ""
}

// SendEmailOTT generates and sends an OTT to the provided email address
func (c *UserController) SendEmailOTT(context *gin.Context, email string, client string, purpose string) error {
	if purpose == ente.ChangeEmailOTTPurpose {
		_, err := c.UserRepo.GetUserIDWithEmail(email)
		if err == nil {
			// email already owned by a user
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
		if !errors.Is(err, sql.ErrNoRows) {
			// unknown error, rethrow
			return stacktrace.Propagate(err, "")
		}
	}
	ott, err := random.GenerateSixDigitOtp()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	// for hard-coded ott, adding  same OTT in db can throw error
	hasHardcodedOTT := false
	if purpose != ente.ChangeEmailOTTPurpose {
		hardCodedOTT := hardcodedOTTForEmail(c.HardCodedOTT, email)
		if hardCodedOTT != "" {
			log.Warn(fmt.Sprintf("returning hardcoded ott for %s", email))
			hasHardcodedOTT = true
			ott = hardCodedOTT
		}
	}
	emailHash, err := crypto.GetHash(email, c.HashingKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	// check if user has already requested for more than 10 codes in last 10mins
	otts, _ := c.UserAuthRepo.GetValidOTTs(emailHash, auth.GetApp(context))
	if len(otts) >= OTTActiveCodeLimit {
		msg := "Too many ott requests in a short duration"
		go c.DiscordController.NotifyPotentialAbuse(msg)
		return stacktrace.Propagate(ente.ErrTooManyBadRequest, msg)
	}

	err = c.UserAuthRepo.AddOTT(emailHash, auth.GetApp(context), ott, time.Microseconds()+OTTValidityDurationInMicroSeconds)
	if !hasHardcodedOTT {
		// ignore error for AddOTT for hardcode OTT. This is to avoid error when unique OTT check fails at db layer
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		log.Info("Added ott for " + emailHash + ": " + ott)
		err = emailOTT(context, email, ott, client, purpose)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
	} else {
		log.Info("Added hard coded ott for " + email + " : " + ott)
	}
	return nil
}

// verifyEmailOtt should be deprecated in favor of verifyEmailOttWithSession once clients are updated.
func (c *UserController) verifyEmailOtt(context *gin.Context, email string, ott string) error {
	ott = strings.TrimSpace(ott)
	app := auth.GetApp(context)
	emailHash, err := crypto.GetHash(email, c.HashingKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	wrongAttempt, err := c.UserAuthRepo.GetMaxWrongAttempts(emailHash, app)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	if wrongAttempt >= OTTWrongAttemptLimit {
		msg := fmt.Sprintf("Too many wrong ott verification attemp for app %s", app)
		go c.DiscordController.NotifyPotentialAbuse(msg)
		return stacktrace.Propagate(ente.ErrTooManyBadRequest, "User needs to wait before active ott are expired")
	}

	otts, err := c.UserAuthRepo.GetValidOTTs(emailHash, app)
	log.Infof("Valid ott (app: %s) for %s are %s", app, emailHash, strings.Join(otts, ","))
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if len(otts) < 1 {
		return stacktrace.Propagate(ente.ErrExpiredOTT, "")
	}
	isValidOTT := false
	for _, validOTT := range otts {
		if ott == validOTT {
			isValidOTT = true
		}
	}
	if !isValidOTT {
		if err = c.UserAuthRepo.RecordWrongAttemptForActiveOtt(emailHash, app); err != nil {
			log.WithError(err).Warn("Failed to track wrong attempt")
		}
		return stacktrace.Propagate(ente.ErrIncorrectOTT, "")
	}
	err = c.UserAuthRepo.RemoveOTT(emailHash, ott, app)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// VerifyEmail validates that the OTT provided in the request is valid for the
// provided email address and if yes returns the users credentials
func (c *UserController) VerifyEmail(context *gin.Context, request ente.EmailVerificationRequest) (ente.EmailAuthorizationResponse, error) {
	email := strings.ToLower(request.Email)
	err := c.verifyEmailOtt(context, email, request.OTT)
	if err != nil {
		return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
	}
	return c.onVerificationSuccess(context, email, request.Source)
}

// ChangeEmail validates that the OTT provided in the request is valid for the
// provided email address and if yes updates the user's existing email address
func (c *UserController) ChangeEmail(ctx *gin.Context, request ente.EmailVerificationRequest) error {
	email := strings.ToLower(request.Email)
	err := c.verifyEmailOtt(ctx, email, request.OTT)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	return c.UpdateEmail(ctx, auth.GetUserID(ctx.Request.Header), email)
}

// UpdateEmail updates the email address of the user with the provided userID
func (c *UserController) UpdateEmail(ctx *gin.Context, userID int64, email string) error {
	_, err := c.UserRepo.GetUserIDWithEmail(email)
	if err == nil {
		// email already owned by a user
		return stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	if !errors.Is(err, sql.ErrNoRows) {
		// unknown error, rethrow
		return stacktrace.Propagate(err, "")
	}
	user, err := c.UserRepo.Get(userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	oldEmail := user.Email
	encryptedEmail, err := crypto.Encrypt(email, c.SecretEncryptionKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	emailHash, err := crypto.GetHash(email, c.HashingKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	err = c.UserRepo.UpdateEmail(userID, encryptedEmail, emailHash)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	_ = emailUtil.SendTemplatedEmail([]string{user.Email}, "ente", "team@ente.io",
		ente.EmailChangedSubject, ente.EmailChangedTemplate, map[string]interface{}{
			"NewEmail": email,
		}, nil)

	err = c.BillingController.UpdateBillingEmail(userID, email)
	if err != nil {
		log.WithError(err).
			WithFields(log.Fields{
				"req_id":  requestid.Get(ctx),
				"user_id": userID,
			}).Error("stripe update email failed")
	}

	// Unsubscribe the old email, subscribe the new one.
	//
	// Note that resubscribing the same email after it has been unsubscribed
	// once works fine.
	//
	// See also: Do not block on mailing list errors
	go func() {
		_ = c.MailingListsController.Unsubscribe(oldEmail)
		_ = c.MailingListsController.Subscribe(email)
	}()

	return nil
}

// Logout removes the token from the cache and database.
// known issue: the token may be still cached in other instances till the expiry time (10min), JWTs might remain too
func (c *UserController) Logout(ctx *gin.Context) error {
	token := auth.GetToken(ctx)
	userID := auth.GetUserID(ctx.Request.Header)
	return c.TerminateSession(userID, token)
}

// GetActiveSessions returns the list of active tokens for userID
func (c *UserController) GetActiveSessions(context *gin.Context, userID int64) ([]ente.Session, error) {
	tokens, err := c.UserAuthRepo.GetActiveSessions(userID, auth.GetApp(context))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return tokens, nil
}

// TerminateSession removes the token for a user from cache and database
func (c *UserController) TerminateSession(userID int64, token string) error {
	c.Cache.Delete(fmt.Sprintf("%s:%s", ente.Photos, token))
	c.Cache.Delete(fmt.Sprintf("%s:%s", ente.Auth, token))
	return stacktrace.Propagate(c.UserAuthRepo.RemoveToken(userID, token), "")
}

func emailOTT(c *gin.Context, to string, ott string, client string, purpose string) error {
	var templateName string
	if auth.GetApp(c) == ente.Auth {
		templateName = ente.AuthOTTTemplate
	} else {
		templateName = ente.PhotosOTTTemplate
	}
	if purpose == ente.ChangeEmailOTTPurpose {
		templateName = ente.ChangeEmailOTTTemplate
	}
	var inlineImages []map[string]interface{}
	inlineImage := make(map[string]interface{})
	inlineImage["cid"] = "img-email-verification-header"
	inlineImage["mime_type"] = "image/png"
	if auth.GetApp(c) == ente.Photos {
		inlineImage["content"] = "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"
	} else {
		inlineImage["content"] = "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"
	}
	inlineImages = append(inlineImages, inlineImage)
	subject := fmt.Sprintf("Email verification code: %s", ott)
	err := emailUtil.SendTemplatedEmail([]string{to}, "Ente", "verify@ente.io",
		subject, templateName, map[string]interface{}{
			"VerificationCode": ott,
		}, inlineImages)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// onVerificationSuccess is called when the user has successfully verified their email address.
// source indicates where the user came from.  It can be nil.
func (c *UserController) onVerificationSuccess(context *gin.Context, email string, source *string) (ente.EmailAuthorizationResponse, error) {
	isTwoFactorEnabled := false

	userID, err := c.UserRepo.GetUserIDWithEmail(email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			userID, _, err = c.createUser(email, source)
			if err != nil {
				return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
			}
		} else {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
	} else {
		isTwoFactorEnabled, err = c.UserRepo.IsTwoFactorEnabled(userID)
		if err != nil {
			return ente.EmailAuthorizationResponse{}, err
		}
	}
	hasPasskeys, err := c.UserRepo.HasPasskeys(userID)
	if err != nil {
		return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
	}

	// if the user has passkeys, we will prioritize that over secret TOTP
	if hasPasskeys {
		passKeySessionID, err := auth.GenerateURLSafeRandomString(PassKeySessionIDLength)
		if err != nil {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
		err = c.PasskeyRepo.AddPasskeyTwoFactorSession(userID, passKeySessionID, time.Microseconds()+TwoFactorValidityDurationInMicroSeconds)
		if err != nil {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
		return ente.EmailAuthorizationResponse{ID: userID, PasskeySessionID: passKeySessionID}, nil
	} else {
		if isTwoFactorEnabled {
			twoFactorSessionID, err := auth.GenerateURLSafeRandomString(TwoFactorSessionIDLength)
			if err != nil {
				return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
			}
			err = c.TwoFactorRepo.AddTwoFactorSession(userID, twoFactorSessionID, time.Microseconds()+TwoFactorValidityDurationInMicroSeconds)
			if err != nil {
				return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
			}
			return ente.EmailAuthorizationResponse{ID: userID, TwoFactorSessionID: twoFactorSessionID}, nil
		}

	}

	token, err := auth.GenerateURLSafeRandomString(TokenLength)
	if err != nil {
		return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
	}
	keyAttributes, err := c.UserRepo.GetKeyAttributes(userID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			err = c.UserAuthRepo.AddToken(userID, auth.GetApp(context), token,
				network.GetClientIP(context), context.Request.UserAgent())
			if err != nil {
				return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
			}
			return ente.EmailAuthorizationResponse{ID: userID, Token: token}, nil
		} else {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
	}
	encryptedToken, err := crypto.GetEncryptedToken(token, keyAttributes.PublicKey)
	if err != nil {
		return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
	}
	err = c.UserAuthRepo.AddToken(userID, auth.GetApp(context), token,
		network.GetClientIP(context), context.Request.UserAgent())
	if err != nil {
		return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
	}
	return ente.EmailAuthorizationResponse{
		ID:             userID,
		KeyAttributes:  &keyAttributes,
		EncryptedToken: encryptedToken,
	}, nil

}

func convertStringToBytes(s string) []byte {
	b, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		log.Fatal(err)
	}
	return b
}

func convertBytesToString(b []byte) string {
	return base64.StdEncoding.EncodeToString(b)
}
