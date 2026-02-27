package authenticator

import (
	"fmt"
	"time"

	"github.com/pquerna/otp"
	"github.com/pquerna/otp/totp"
)

type TOTPCode struct {
	Issuer    string
	Account   string
	Code      string
	ExpiresIn int // seconds until this code expires
}

// GenerateTOTPCode parses an otpauth:// URI and returns the current TOTP code.
func GenerateTOTPCode(otpauthURI string) (*TOTPCode, error) {
	// Parse the otpauth://totp/Issuer:Account?secret=...&period=X&... URI
	key, err := otp.NewKeyFromURL(otpauthURI)
	if err != nil {
		return nil, fmt.Errorf("failed to parse otpauth URI: %v", err)
	}

	// Check for hotp entries
	if key.Type() != "totp" {
		return nil, fmt.Errorf("unsupported OTP type: %s", key.Type())
	}

	now := time.Now()
	period := uint(key.Period())
	if period == 0 {
		period = 30 // default, per RFC 6238 section 4.1
	}

	code, err := totp.GenerateCodeCustom(key.Secret(), now, totp.ValidateOpts{
		Period:    period,
		Skew:      0,
		Digits:    key.Digits(),
		Algorithm: key.Algorithm(),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to generate TOTP code: %v", err)
	}

	expiresIn := int(period) - int(now.Unix()%int64(period))

	return &TOTPCode{
		Issuer:    key.Issuer(),
		Account:   key.AccountName(),
		Code:      code,
		ExpiresIn: expiresIn,
	}, nil
}
