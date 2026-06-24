package handler

import (
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ente/museum/ente"
	"github.com/ente/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	logtest "github.com/sirupsen/logrus/hooks/test"
	"github.com/stretchr/testify/require"
)

func TestErrorDoesNotLogExpectedErrors(t *testing.T) {
	gin.SetMode(gin.TestMode)

	for _, tt := range []struct {
		name       string
		err        error
		wantStatus int
	}{
		{
			name:       "storage limit",
			err:        ente.ErrStorageLimitExceeded,
			wantStatus: http.StatusUpgradeRequired,
		},
		{
			name:       "no active subscription",
			err:        ente.ErrNoActiveSubscription,
			wantStatus: http.StatusPaymentRequired,
		},
		{
			name:       "not found api error",
			err:        ente.ErrNotFoundError.NewErr("missing"),
			wantStatus: http.StatusNotFound,
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			recorder, ctx := testContext()
			hook := testLogHook(t)

			Error(ctx, stacktrace.Propagate(tt.err, ""))

			require.Equal(t, tt.wantStatus, recorder.Code)
			require.Empty(t, hook.AllEntries())
		})
	}
}

func TestErrorLogsWarnForExpectedClientErrors(t *testing.T) {
	gin.SetMode(gin.TestMode)

	for _, tt := range []struct {
		name       string
		err        error
		wantStatus int
	}{
		{
			name:       "sql no rows",
			err:        sql.ErrNoRows,
			wantStatus: http.StatusNotFound,
		},
		{
			name:       "incorrect ott",
			err:        ente.ErrIncorrectOTT,
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "incorrect totp",
			err:        ente.ErrIncorrectTOTP,
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "authentication required",
			err:        ente.ErrAuthenticationRequired,
			wantStatus: http.StatusUnauthorized,
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			recorder, ctx := testContext()
			hook := testLogHook(t)

			Error(ctx, stacktrace.Propagate(tt.err, ""))

			require.Equal(t, tt.wantStatus, recorder.Code)
			entry := hook.LastEntry()
			require.NotNil(t, entry)
			require.Equal(t, log.WarnLevel, entry.Level)
			require.Equal(t, "Request failed", entry.Message)
		})
	}
}

func TestErrorLogsUnexpectedErrors(t *testing.T) {
	gin.SetMode(gin.TestMode)

	recorder, ctx := testContext()
	hook := testLogHook(t)

	Error(ctx, errors.New("boom"))

	require.Equal(t, http.StatusInternalServerError, recorder.Code)
	entry := hook.LastEntry()
	require.NotNil(t, entry)
	require.Equal(t, log.ErrorLevel, entry.Level)
	require.Equal(t, "Request failed", entry.Message)
}

func TestErrorPreservesNotFoundAPIErrorResponse(t *testing.T) {
	gin.SetMode(gin.TestMode)

	recorder, ctx := testContext()

	Error(ctx, stacktrace.Propagate(&ente.ErrNotFoundError, ""))

	require.Equal(t, http.StatusNotFound, recorder.Code)

	var body ente.ApiError
	require.NoError(t, json.Unmarshal(recorder.Body.Bytes(), &body))
	require.Equal(t, ente.NotFoundError, body.Code)
}

func testContext() (*httptest.ResponseRecorder, *gin.Context) {
	recorder := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(recorder)
	ctx.Request = httptest.NewRequest(http.MethodGet, "/files/data/preview", nil)
	return recorder, ctx
}

func testLogHook(t *testing.T) *logtest.Hook {
	t.Helper()
	logger := log.StandardLogger()
	originalHooks := logger.ReplaceHooks(make(log.LevelHooks))
	t.Cleanup(func() {
		logger.ReplaceHooks(originalHooks)
	})

	hook := logtest.NewGlobal()
	t.Cleanup(hook.Reset)
	return hook
}
