package handler

import (
	"database/sql"
	"errors"
	"io"
	"net/http"
	"syscall"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	log "github.com/sirupsen/logrus"
)

// Error parses the error, translates it into an HTTP response and aborts
// the request
func Error(c *gin.Context, err error) {
	contextLogger := log.WithError(err).
		WithFields(log.Fields{
			"req_id":  requestid.Get(c),
			"user_id": auth.GetUserID(c.Request.Header),
		})
	isClientError := false
	// Tip: To trigger the "unexpected EOF" error, connect with:
	//
	//    echo "GET /ping HTTP/1.0\r\nContent-Length: 300\r\n\r\n" | nc localhost 8080
	if errors.Is(err, ente.ErrStorageLimitExceeded) ||
		errors.Is(err, ente.ErrNoActiveSubscription) ||
		errors.Is(err, ente.ErrInvalidPassword) ||
		errors.Is(err, io.ErrUnexpectedEOF) ||
		errors.Is(err, syscall.EPIPE) ||
		errors.Is(err, syscall.ECONNRESET) {
		isClientError = true
	}
	unWrappedErr := errors.Unwrap(err)
	if unWrappedErr == nil {
		unWrappedErr = err
	}
	enteApiErr, isEnteApiErr := unWrappedErr.(*ente.ApiError)
	if isEnteApiErr && enteApiErr.HttpStatusCode >= 400 && enteApiErr.HttpStatusCode < 500 {
		isClientError = true
	}
	if isClientError {
		contextLogger.Warn("Request failed")
	} else {
		contextLogger.Error("Request failed")
	}
	if isEnteApiErr {
		c.AbortWithStatusJSON(enteApiErr.HttpStatusCode, enteApiErr)
	} else if httpStatus := httpStatusCode(err); httpStatus != 0 {
		c.AbortWithStatus(httpStatus)
	} else {
		if _, ok := stacktrace.RootCause(err).(validator.ValidationErrors); ok {
			c.AbortWithStatus(http.StatusBadRequest)
		} else if isClientError {
			c.AbortWithStatus(http.StatusBadRequest)
		} else {
			c.AbortWithStatus(http.StatusInternalServerError)
		}
	}
}

// If `err` directly maps to an HTTP status code, return the HTTP status code.
// Otherwise return 0.
func httpStatusCode(err error) int {
	switch {
	case errors.Is(err, ente.ErrNotFound) ||
		errors.Is(err, sql.ErrNoRows):
		return http.StatusNotFound
	case errors.Is(err, ente.ErrBadRequest) ||
		errors.Is(err, ente.ErrCannotDowngrade) ||
		errors.Is(err, ente.ErrCannotSwitchPaymentProvider):
		return http.StatusBadRequest
	case errors.Is(err, ente.ErrTooManyBadRequest):
		return http.StatusTooManyRequests
	case errors.Is(err, ente.ErrPermissionDenied):
		return http.StatusForbidden
	case errors.Is(err, ente.ErrIncorrectOTT) ||
		errors.Is(err, ente.ErrIncorrectTOTP) ||
		errors.Is(err, ente.ErrInvalidPassword) ||
		errors.Is(err, ente.ErrAuthenticationRequired):
		return http.StatusUnauthorized
	case errors.Is(err, ente.ErrExpiredOTT):
		return http.StatusGone
	case errors.Is(err, ente.ErrNoActiveSubscription) ||
		errors.Is(err, ente.ErrSharingDisabledForFreeAccounts):
		return http.StatusPaymentRequired
	case errors.Is(err, ente.ErrStorageLimitExceeded):
		return http.StatusUpgradeRequired
	case errors.Is(err, ente.ErrFileTooLarge):
		return http.StatusRequestEntityTooLarge
	case errors.Is(err, ente.ErrVersionMismatch) ||
		errors.Is(err, ente.ErrCanNotInviteUserWithPaidPlan):
		return http.StatusConflict
	case errors.Is(err, ente.ErrBatchSizeTooLarge):
		return http.StatusRequestEntityTooLarge
	case errors.Is(err, ente.ErrCanNotInviteUserAlreadyInFamily):
		return http.StatusNotAcceptable
	case errors.Is(err, ente.ErrFamilySizeLimitReached):
		return http.StatusPreconditionFailed
	case errors.Is(err, ente.ErrNotImplemented):
		return http.StatusNotImplemented
	default:
		return 0
	}
}
