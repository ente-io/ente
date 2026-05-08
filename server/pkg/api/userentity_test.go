package api

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/internal/testutil"
	userentitycontroller "github.com/ente-io/museum/pkg/controller/userentity"
	userentityrepo "github.com/ente-io/museum/pkg/repo/userentity"
	"github.com/gin-gonic/gin"
)

func TestCreateUserEntityKeyIsIdempotentForReplay(t *testing.T) {
	handler, db := setupUserEntityHandlerTest(t)

	userID := testutil.InsertUser(t, db, testutil.UserFixture{
		UserID:       201,
		Email:        "userentity-key-conflict@ente.com",
		CreationTime: 1,
	})

	body := map[string]any{
		"type":         "memory",
		"encryptedKey": "encrypted-key",
		"header":       "header",
	}

	first := performCreateUserEntityKeyRequest(t, handler, userID, body)
	if first.Code != http.StatusOK {
		t.Fatalf("unexpected status code on first create: got %d want %d; body=%s", first.Code, http.StatusOK, first.Body.String())
	}

	second := performCreateUserEntityKeyRequest(t, handler, userID, body)
	if second.Code != http.StatusOK {
		t.Fatalf("unexpected status code on duplicate replay: got %d want %d; body=%s", second.Code, http.StatusOK, second.Body.String())
	}
}

func TestCreateUserEntityKeyReturnsAlreadyExistsForConflictingCreate(t *testing.T) {
	handler, db := setupUserEntityHandlerTest(t)

	userID := testutil.InsertUser(t, db, testutil.UserFixture{
		UserID:       202,
		Email:        "userentity-key-already-exists@ente.com",
		CreationTime: 1,
	})

	firstBody := map[string]any{
		"type":         "memory",
		"encryptedKey": "encrypted-key",
		"header":       "header",
	}
	secondBody := map[string]any{
		"type":         "memory",
		"encryptedKey": "different-encrypted-key",
		"header":       "different-header",
	}

	first := performCreateUserEntityKeyRequest(t, handler, userID, firstBody)
	if first.Code != http.StatusOK {
		t.Fatalf("unexpected status code on first create: got %d want %d; body=%s", first.Code, http.StatusOK, first.Body.String())
	}

	second := performCreateUserEntityKeyRequest(t, handler, userID, secondBody)
	assertAPIErrorResponse(t, second, http.StatusConflict, ente.AlreadyExists, "Key already exists")
}

func setupUserEntityHandlerTest(t *testing.T) (*UserEntityHandler, *sql.DB) {
	t.Helper()

	testutil.WithServerRoot(t)

	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() {
		testutil.ResetTables(t, db)
	})

	return &UserEntityHandler{
		Controller: &userentitycontroller.Controller{
			Repo: &userentityrepo.Repository{DB: db},
		},
	}, db
}

func performCreateUserEntityKeyRequest(
	t *testing.T,
	handler *UserEntityHandler,
	userID int64,
	body map[string]any,
) *httptest.ResponseRecorder {
	t.Helper()

	gin.SetMode(gin.TestMode)

	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("failed to marshal request body: %v", err)
	}

	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/user-entity/key", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Auth-User-ID", strconv.FormatInt(userID, 10))

	router := gin.New()
	router.POST("/user-entity/key", handler.CreateKey)
	router.ServeHTTP(recorder, req)

	return recorder
}
