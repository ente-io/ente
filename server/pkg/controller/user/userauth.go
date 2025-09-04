package user

import (
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	t "time"

	"github.com/ente-io/museum/pkg/utils/random"

	"github.com/ente-io/museum/pkg/utils/config"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/gin-contrib/requestid"
	"github.com/spf13/viper"

	"github.com/ente-io/museum/ente"
	emailCtrl "github.com/ente-io/museum/pkg/controller/email"
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
func (c *UserController) SendEmailOTT(context *gin.Context, email string, purpose string, mobile bool) error {
	if err := c.validateSendOTT(context, email, purpose); err != nil {
		return err
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
	app := auth.GetApp(context)
	otts, _ := c.UserAuthRepo.GetValidOTTs(emailHash, app)
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
		err = emailOTT(app, email, ott, purpose, mobile)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
	} else {
		log.Info("Added hard coded ott for " + email + " : " + ott)
	}
	return nil
}

func (c *UserController) isEmailAlreadyUsed(email string) error {
	_, err := c.UserRepo.GetUserIDWithEmail(email)
	if err == nil {
		// email already owned by a user
		return stacktrace.Propagate(ente.ErrPermissionDenied, "email already belongs to a user")
	}
	if !errors.Is(err, sql.ErrNoRows) {
		// unknown error, rethrow
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (c *UserController) validateSendOTT(ctx *gin.Context, email string, purpose string) error {
	if purpose == ente.ChangeEmailOTTPurpose {
		if err := c.isEmailAlreadyUsed(email); err != nil {
			return err
		}
	}
	isSignUpComplete, err := c.isSignUpComplete(email)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if purpose == ente.SignUpOTTPurpose && viper.GetBool("internal.disable-registration") && !isSignUpComplete {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "registration is disabled")
	}
	//
	var registrationErr error
	if purpose == ente.SignUpOTTPurpose && isSignUpComplete {
		registrationErr = stacktrace.Propagate(ente.ErrUserAlreadyRegistered, "user has already completed sign up process")
	}
	if purpose == ente.LoginOTTPurpose && !isSignUpComplete {
		registrationErr = stacktrace.Propagate(ente.ErrUserNotRegistered, "user has not completed sign up process")
	}
	// if no registration error, return
	if registrationErr == nil {
		return registrationErr
	}
	// check & swallow registration information error if too many such
	// errors are generated in a short time
	if limiter, limitErr := c.OTTLimiter.Get(ctx, "send-ott"); limitErr != nil {
		if limiter.Reached {
			go c.DiscordController.NotifyPotentialAbuse("swallowing send-ott registration error")
			return nil
		}
	}
	return registrationErr
}

// isSignUpComplete checks if the user has completed the entire signup process.
// Sign up is considered complete if the user has verified their email address and their key attributes are set.
func (c *UserController) isSignUpComplete(email string) (bool, error) {
	userID, err := c.UserRepo.GetUserIDWithEmail(email)
	if err != nil && errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	_, keyErr := c.UserRepo.GetKeyAttributes(userID)
	if keyErr != nil && errors.Is(keyErr, sql.ErrNoRows) {
		return false, nil
	}
	if keyErr != nil {
		return false, stacktrace.Propagate(keyErr, "")
	}
	return true, nil
}

func (c *UserController) AddAdminOtt(req ente.AdminOttReq) error {
	emailHash, err := crypto.GetHash(req.Email, c.HashingKey)
	if err != nil {
		log.WithError(err).Error("Failed to get hash")
		return nil
	}
	err = c.UserAuthRepo.AddOTT(emailHash, req.App, req.Code, req.ExpiryTime)
	if err != nil {
		log.WithError(err).Error("Failed to add ott")
		return stacktrace.Propagate(err, "")
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

func (c *UserController) AddTokenAndNotify(userID int64, app ente.App, token string, ip string, userAgent string) error {
	err := c.UserAuthRepo.AddToken(userID, app, token, ip, userAgent)
	if err != nil {
		return stacktrace.Propagate(err, "failed to insert token")
	}

	go func() {
		user, userErr := c.UserRepo.GetUserByIDInternal(userID)
		if userErr != nil {
			log.WithError(userErr).Error("Failed to get user")
			return
		}
		emailSendErr := emailUtil.SendTemplatedEmail([]string{user.Email}, "Ente", "team@ente.io", emailCtrl.LoginSuccessSubject, emailCtrl.LoginSuccessTemplate, map[string]interface{}{
			"Date": t.Now().UTC().Format("02 Jan, 2006 15:04"),
		}, nil)
		if emailSendErr != nil {
			log.WithError(emailSendErr).Error("Failed to send email")
		}
	}()
	return nil
}

// TerminateSession removes the token for a user from cache and database
func (c *UserController) TerminateSession(userID int64, token string) error {
	c.Cache.Delete(fmt.Sprintf("%s:%s", ente.Photos, token))
	c.Cache.Delete(fmt.Sprintf("%s:%s", ente.Auth, token))
	return stacktrace.Propagate(c.UserAuthRepo.RemoveToken(userID, token), "")
}

func emailOTT(app ente.App, to string, ott string, purpose string, mobile bool) error {
	var templateName string
	if purpose == ente.ChangeEmailOTTPurpose {
		templateName = ente.ChangeEmailOTTTemplate
	} else {
		if mobile && app == ente.Photos {
			templateName = ente.OTTMobileTemplate
		} else {
			templateName = ente.OTTTemplate
		}
	}
	subject := fmt.Sprintf("Verification code: %s", ott)
	err := emailUtil.SendTemplatedEmail([]string{to}, "Ente", "verify@ente.io",
		subject, templateName, map[string]interface{}{
			"VerificationCode": ott,
		}, nil)
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
			if viper.GetBool("internal.disable-registration") {
				return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(ente.ErrPermissionDenied, "")
			} else {
				userID, _, err = c.createUser(email, source)
				if err != nil {
					return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
				}
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
	var passKeySessionID, twoFactorSessionID string

	if hasPasskeys {
		passKeySessionID, err = auth.GenerateURLSafeRandomString(PassKeySessionIDLength)
		if err != nil {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
		err = c.PasskeyRepo.AddPasskeyTwoFactorSession(userID, passKeySessionID, time.Microseconds()+TwoFactorValidityDurationInMicroSeconds)
		if err != nil {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
	}
	if isTwoFactorEnabled {
		twoFactorSessionID, err = auth.GenerateURLSafeRandomString(TwoFactorSessionIDLength)
		if err != nil {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
		err = c.TwoFactorRepo.AddTwoFactorSession(userID, twoFactorSessionID, time.Microseconds()+TwoFactorValidityDurationInMicroSeconds)
		if err != nil {
			return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
		}
	}
	accountsUrl := viper.GetString("apps.accounts")
	if hasPasskeys && isTwoFactorEnabled {
		return ente.EmailAuthorizationResponse{ID: userID, PasskeySessionID: passKeySessionID, AccountsUrl: accountsUrl, TwoFactorSessionIDV2: twoFactorSessionID}, nil
	} else if hasPasskeys {
		return ente.EmailAuthorizationResponse{ID: userID, PasskeySessionID: passKeySessionID, AccountsUrl: accountsUrl}, nil
	} else if isTwoFactorEnabled {
		return ente.EmailAuthorizationResponse{ID: userID, TwoFactorSessionID: twoFactorSessionID}, nil
	}

	token, err := auth.GenerateURLSafeRandomString(TokenLength)
	if err != nil {
		return ente.EmailAuthorizationResponse{}, stacktrace.Propagate(err, "")
	}
	keyAttributes, err := c.UserRepo.GetKeyAttributes(userID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// user creation is pending on key attributes set based on the password.
			// No need to send login notification
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
	err = c.AddTokenAndNotify(userID, auth.GetApp(context), token,
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
		panic(fmt.Sprintf("failed to base64dDecode string %s", s))
	}
	return b
}

func convertBytesToString(b []byte) string {
	return base64.StdEncoding.EncodeToString(b)
}
