package user

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"errors"
	"fmt"
	"github.com/ente-io/go-srp"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"net/http"
	"strings"
	"time"
)

const (
	Srp4096Params = 4096
	// MaxUnverifiedSessionInAnHour is the number of unverified sessions in the last hour
	MaxUnverifiedSessionInAnHour = 10
)

func (c *UserController) SetupSRP(context *gin.Context, userID int64, req ente.SetupSRPRequest) (*ente.SetupSRPResponse, error) {
	srpB, sessionID, err := c.createAndInsertSRPSession(context, req.SrpUserID, req.SRPVerifier, req.SRPA)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	setupID, err := c.UserAuthRepo.InsertTempSRPSetup(context, req, userID, sessionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to add entry in setup table")
	}

	return &ente.SetupSRPResponse{
		SetupID: *setupID,
		SRPB:    *srpB,
	}, nil
}

func (c *UserController) CompleteSRPSetup(context *gin.Context, req ente.CompleteSRPSetupRequest) (*ente.CompleteSRPSetupResponse, error) {
	userID := auth.GetUserID(context.Request.Header)
	setup, err := c.UserAuthRepo.GetTempSRPSetupEntity(context, req.SetupID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	srpM2, err := c.verifySRPSession(context, setup.Verifier, setup.SessionID, req.SRPM1)
	if err != nil {
		return nil, err
	}
	err = c.UserAuthRepo.InsertSRPAuth(context, userID, setup.SRPUserID, setup.Verifier, setup.Salt)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to add entry in srp auth")
	}
	return &ente.CompleteSRPSetupResponse{
		SetupID: req.SetupID,
		SRPM2:   *srpM2,
	}, nil
}

// UpdateSrpAndKeyAttributes updates the SRP and keys attributes if the SRP setup is successfully done
func (c *UserController) UpdateSrpAndKeyAttributes(context *gin.Context,
	userID int64,
	req ente.UpdateSRPAndKeysRequest,
	shouldClearTokens bool,
) (*ente.UpdateSRPSetupResponse, error) {
	setup, err := c.UserAuthRepo.GetTempSRPSetupEntity(context, req.SetupID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	srpM2, err := c.verifySRPSession(context, setup.Verifier, setup.SessionID, req.SRPM1)
	if err != nil {
		return nil, err
	}
	err = c.UserAuthRepo.InsertOrUpdateSRPAuthAndKeyAttr(context, userID, req, setup)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to add entry in srp auth")
	}

	if shouldClearTokens {
		token := auth.GetToken(context)
		err = c.UserAuthRepo.RemoveAllOtherTokens(userID, token)
		if err != nil {
			return nil, err
		}
	} else {
		logrus.WithField("user_id", userID).Info("not clearing tokens")
	}

	return &ente.UpdateSRPSetupResponse{
		SetupID: req.SetupID,
		SRPM2:   *srpM2,
	}, nil
}

func (c *UserController) GetSRPAttributes(context *gin.Context, email string) (*ente.GetSRPAttributesResponse, error) {
	userID, err := c.UserRepo.GetUserIDWithEmail(email)
	if err != nil {
		if !errors.Is(err, sql.ErrNoRows) {
			return nil, stacktrace.Propagate(err, "failed to get user id")
		}
		if limit, limitErr := c.SRPLimiter.Get(context, "get_srp"); limitErr == nil {
			if limit.Reached {
				c.DiscordController.NotifyPotentialAbuse("swallowing missing srp errors")
				return fSrpAttributes(email, c.HashingKey)
			}
		}
		return nil, stacktrace.Propagate(err, "failed to get user")
	}
	srpAttributes, err := c.UserAuthRepo.GetSRPAttributes(userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return srpAttributes, nil
}

func (c *UserController) CreateSrpSession(context *gin.Context, req ente.CreateSRPSessionRequest) (*ente.CreateSRPSessionResponse, error) {
	srpAuthEntity, err := c.UserAuthRepo.GetSRPAuthEntityBySRPUserID(context, req.SRPUserID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return fCreateSession(req.SRPUserID.String(), req.SRPA)
		}
		return nil, stacktrace.Propagate(err, "failed to get srp auth entity")
	}
	isEmailMFAEnabled, err := c.UserAuthRepo.IsEmailMFAEnabled(context, srpAuthEntity.UserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	if *isEmailMFAEnabled {
		return nil, stacktrace.Propagate(&ente.ApiError{
			Code:           "EMAIL_MFA_ENABLED",
			Message:        "Email MFA is enabled",
			HttpStatusCode: http.StatusConflict,
		}, "email mfa is enabled")
	}

	srpBBase64, sessionID, err := c.createAndInsertSRPSession(context, req.SRPUserID, srpAuthEntity.Verifier, req.SRPA)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &ente.CreateSRPSessionResponse{
		SRPB:      *srpBBase64,
		SessionID: *sessionID,
	}, nil
}

func (c *UserController) VerifySRPSession(context *gin.Context, req ente.VerifySRPSessionRequest) (*ente.EmailAuthorizationResponse, error) {
	srpAuthEntity, err := c.UserAuthRepo.GetSRPAuthEntityBySRPUserID(context, req.SRPUserID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, stacktrace.Propagate(ente.ErrInvalidPassword, "missing session, return invalid password")
		}
		return nil, stacktrace.Propagate(err, "")
	}
	srpM2, err := c.verifySRPSession(context, srpAuthEntity.Verifier, req.SessionID, req.SRPM1)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	user, err := c.UserRepo.Get(srpAuthEntity.UserID)
	if err != nil {
		return nil, err
	}
	verResponse, err := c.onVerificationSuccess(context, user.Email, nil)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	verResponse.SrpM2 = srpM2
	return &verResponse, nil
}

func (c *UserController) createAndInsertSRPSession(
	gContext *gin.Context,
	srpUserID uuid.UUID,
	srpVerifier string,
	srpA string,
) (*string, *uuid.UUID, error) {
	srpABytes := convertStringToBytes(srpA)
	if len(srpABytes) != 512 {
		return nil, nil, ente.NewBadRequestWithMessage("Invalid length for srpA")
	}
	unverifiedSessions, err := c.UserAuthRepo.GetUnverifiedSessionsInLastHour(srpUserID)
	if err != nil {
		return nil, nil, stacktrace.Propagate(err, "")
	}
	if unverifiedSessions >= MaxUnverifiedSessionInAnHour {
		go c.DiscordController.NotifyPotentialAbuse(fmt.Sprintf("Too many unverified sessions for user %s", srpUserID.String()))
		return nil, nil, stacktrace.Propagate(&ente.ApiError{
			Code:           "TOO_MANY_UNVERIFIED_SESSIONS",
			HttpStatusCode: http.StatusTooManyRequests,
		}, "")

	}

	serverSecret := srp.GenKey()
	srpParams := srp.GetParams(Srp4096Params)
	srpServer := srp.NewServer(srpParams, convertStringToBytes(srpVerifier), serverSecret)

	if srpServer == nil {
		return nil, nil, stacktrace.NewError("server is nil")
	}

	srpServer.SetA(srpABytes)
	srpB := srpServer.ComputeB()

	if srpB == nil {
		return nil, nil, stacktrace.NewError("srpB is nil")
	}

	if len(srpB) != 512 {
		return nil, nil, ente.NewBadRequestWithMessage("Invalid length for srpB")
	}

	sessionID, err := c.UserAuthRepo.AddSRPSession(srpUserID, convertBytesToString(serverSecret), srpA)

	if err != nil {
		return nil, nil, stacktrace.Propagate(err, "")
	}

	srpBBase64 := convertBytesToString(srpB)
	return &srpBBase64, &sessionID, nil
}

func (c *UserController) verifySRPSession(ctx context.Context,
	srpVerifier string,
	sessionID uuid.UUID,
	srpM1 string,
) (*string, error) {
	srpM1Bytes := convertStringToBytes(srpM1)
	if len(srpM1Bytes) != 32 {
		return nil, ente.NewBadRequestWithMessage(fmt.Sprintf("srpM1 size is %d, expected 32", len(srpM1Bytes)))
	}
	srpSession, err := c.UserAuthRepo.GetSrpSessionEntity(ctx, sessionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if srpSession.IsVerified {
		return nil, stacktrace.Propagate(&ente.ApiError{
			Code:           "SESSION_ALREADY_VERIFIED",
			HttpStatusCode: http.StatusGone,
		}, "")
	} else if srpSession.AttemptCount >= 5 {
		return nil, stacktrace.Propagate(&ente.ApiError{
			Code:           "TOO_MANY_WRONG_ATTEMPTS",
			HttpStatusCode: http.StatusGone,
		}, "")
	}

	srpParams := srp.GetParams(Srp4096Params)
	srpServer := srp.NewServer(srpParams, convertStringToBytes(srpVerifier), convertStringToBytes(srpSession.ServerKey))

	if srpServer == nil {
		return nil, stacktrace.NewError("server is nil")
	}
	srpABytes := convertStringToBytes(srpSession.SRP_A)

	srpServer.SetA(srpABytes)

	srpM2Bytes, err := srpServer.CheckM1(srpM1Bytes)

	if err != nil {
		err2 := c.UserAuthRepo.IncrementSrpSessionAttemptCount(ctx, sessionID)
		if err2 != nil {
			return nil, stacktrace.Propagate(err2, "")
		}
		return nil, stacktrace.Propagate(ente.ErrInvalidPassword, "failed to verify srp session")
	} else {
		err2 := c.UserAuthRepo.SetSrpSessionVerified(ctx, sessionID)
		if err2 != nil {
			return nil, stacktrace.Propagate(err2, "")
		}
	}
	srpM2 := convertBytesToString(srpM2Bytes)
	return &srpM2, nil
}

func fSrpAttributes(email string, hashKey []byte) (*ente.GetSRPAttributesResponse, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	emailHasher := sha256.New()
	emailHasher.Write([]byte("email-salt-purpose-and-uuid"))
	emailHasher.Write([]byte(email))
	emailHasher.Write(hashKey)
	emailHash := emailHasher.Sum(nil)

	kekSaltMaker := sha256.New()
	kekSaltMaker.Write([]byte("kek-salt-purpose"))
	kekSaltMaker.Write([]byte(email))
	kekSaltMaker.Write(hashKey)
	kekSaltHash := kekSaltMaker.Sum(nil)

	// Generate UUIDv4 from first 16 bytes of hash
	uuidBytes := make([]byte, 16)
	copy(uuidBytes, emailHash[:16])
	// Set version bits (4) and variant bits (RFC 4122)
	uuidBytes[6] = (uuidBytes[6] & 0x0f) | 0x40 // Version 4
	uuidBytes[8] = (uuidBytes[8] & 0x3f) | 0x80 // Variant RFC 4122
	uuidStr := fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
		uuidBytes[:4],
		uuidBytes[4:6],
		uuidBytes[6:8],
		uuidBytes[8:10],
		uuidBytes[10:16])
	memLimit := 1073741824
	opsLimit := 4
	emailVerificationEnabled := false
	if emailHash[16]%2 == 0 {
		memLimit = 268435456
		opsLimit = 16
	}
	if emailHash[16]%5 == 0 {
		emailVerificationEnabled = true
	}
	return &ente.GetSRPAttributesResponse{
		SRPUserID: uuidStr,
		SRPSalt:   convertBytesToString(emailHash[16:32]),
		KekSalt:   convertBytesToString(kekSaltHash[16:32]),
		MemLimit:  memLimit,
		OpsLimit:  opsLimit,

		IsEmailMFAEnabled: emailVerificationEnabled,
	}, nil
}

func fCreateSession(srpUserID string, srpA string) (*ente.CreateSRPSessionResponse, error) {
	srpABytes := convertStringToBytes(srpA)
	if len(srpABytes) != 512 {
		return nil, ente.NewBadRequestWithMessage("Invalid length for srpA")
	}
	time.Sleep(20 * time.Millisecond)
	// generate 512 bytes of random data
	srpBBytes := make([]byte, 512)
	_, err := rand.Read(srpBBytes)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to generate random bytes")
	}

	return &ente.CreateSRPSessionResponse{
		SessionID: uuid.New(),
		SRPB:      convertBytesToString(srpBBytes[:512]),
	}, nil
}
