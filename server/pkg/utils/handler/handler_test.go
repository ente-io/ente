package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	logtest "github.com/sirupsen/logrus/hooks/test"
	"github.com/stretchr/testify/require"
)

func TestErrorLogsWarnForNotFoundAPIError(t *testing.T) {
	gin.SetMode(gin.TestMode)

	recorder, ctx := testContext()
	hook := testLogHook(t)

	Error(ctx, stacktrace.Propagate(&ente.ErrNotFoundError, ""))

	require.Equal(t, http.StatusNotFound, recorder.Code)

	entry := hook.LastEntry()
	require.NotNil(t, entry)
	require.Equal(t, log.WarnLevel, entry.Level)
	require.Equal(t, "Request failed", entry.Message)
}

func TestExpectedErrorPreservesNotFoundAPIErrorResponseWithoutLog(t *testing.T) {
	gin.SetMode(gin.TestMode)

	recorder, ctx := testContext()
	hook := testLogHook(t)

	ExpectedError(ctx, stacktrace.Propagate(&ente.ErrNotFoundError, ""))

	require.Equal(t, http.StatusNotFound, recorder.Code)
	require.Empty(t, hook.AllEntries())

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
	originalOut := logger.Out
	originalFormatter := logger.Formatter
	originalLevel := logger.Level
	t.Cleanup(func() {
		logger.ReplaceHooks(originalHooks)
		logger.SetOutput(originalOut)
		logger.SetFormatter(originalFormatter)
		logger.SetLevel(originalLevel)
	})

	hook := logtest.NewGlobal()
	t.Cleanup(hook.Reset)
	return hook
}
