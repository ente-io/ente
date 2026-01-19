package llmchat

import (
	"context"
	"database/sql"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/google/uuid"
	_ "github.com/lib/pq"
	log "github.com/sirupsen/logrus"
)

var testDB *sql.DB

func TestMain(m *testing.M) {
	if os.Getenv("ENV") != "test" {
		log.Fatalf("Not running tests in non-test environment")
		os.Exit(0)
	}

	var err error
	testDB, err = setupDatabase()
	if err != nil {
		log.Fatalf("error setting up test database: %v", err)
	}

	exitCode := m.Run()

	if err := testDB.Close(); err != nil {
		log.Fatalf("error closing test database connection: %v", err)
	}
	os.Exit(exitCode)
}

func setupDatabase() (*sql.DB, error) {
	db, err := sql.Open("postgres", "user=test_user password=test_pass host=localhost dbname=ente_test_db sslmode=disable")
	if err != nil {
		return nil, err
	}

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		return nil, err
	}

	cwd, _ := os.Getwd()
	cwd = strings.Split(cwd, "/pkg/")[0]
	configFilePath := "file://" + filepath.Join(cwd, "migrations")

	mig, err := migrate.NewWithDatabaseInstance(
		configFilePath, "ente_test_db", driver)
	if err != nil {
		return nil, err
	}

	if err := mig.Up(); err != nil && err != migrate.ErrNoChange {
		return nil, err
	}

	return db, nil
}

func createTestUser(t *testing.T) int64 {
	t.Helper()

	var userID int64
	err := testDB.QueryRow(
		`INSERT INTO users (creation_time) VALUES ($1) RETURNING user_id`,
		time.Now().UnixMicro(),
	).Scan(&userID)
	if err != nil {
		t.Fatalf("failed to create test user: %v", err)
	}

	return userID
}

func cleanupUser(t *testing.T, userID int64) {
	t.Helper()

	if _, err := testDB.Exec(`DELETE FROM llmchat_messages WHERE user_id = $1`, userID); err != nil {
		t.Fatalf("failed to cleanup llmchat messages: %v", err)
	}
	if _, err := testDB.Exec(`DELETE FROM llmchat_sessions WHERE user_id = $1`, userID); err != nil {
		t.Fatalf("failed to cleanup llmchat sessions: %v", err)
	}
	if _, err := testDB.Exec(`DELETE FROM llmchat_key WHERE user_id = $1`, userID); err != nil {
		t.Fatalf("failed to cleanup llmchat key: %v", err)
	}
	if _, err := testDB.Exec(`DELETE FROM users WHERE user_id = $1`, userID); err != nil {
		t.Fatalf("failed to cleanup test user: %v", err)
	}
}

func ensureKey(t *testing.T, repo *Repository, userID int64) {
	t.Helper()

	_, err := repo.UpsertKey(context.Background(), userID, model.UpsertKeyRequest{
		EncryptedKey: "enc-key",
		Header:       "hdr-key",
	})
	if err != nil {
		t.Fatalf("failed to upsert llmchat key: %v", err)
	}
}

func assertSessionDiffOrder(t *testing.T, entries []model.SessionDiffEntry) {
	t.Helper()

	for i := 1; i < len(entries); i++ {
		prev := entries[i-1]
		curr := entries[i]
		if prev.UpdatedAt > curr.UpdatedAt {
			t.Fatalf("expected session diff ordered by updated_at")
		}
		if prev.UpdatedAt == curr.UpdatedAt && prev.SessionUUID > curr.SessionUUID {
			t.Fatalf("expected session diff ordered by updated_at and session_uuid")
		}
	}
}

func assertMessageDiffOrder(t *testing.T, entries []model.MessageDiffEntry) {
	t.Helper()

	for i := 1; i < len(entries); i++ {
		prev := entries[i-1]
		curr := entries[i]
		if prev.UpdatedAt > curr.UpdatedAt {
			t.Fatalf("expected message diff ordered by updated_at")
		}
		if prev.UpdatedAt == curr.UpdatedAt && prev.MessageUUID > curr.MessageUUID {
			t.Fatalf("expected message diff ordered by updated_at and message_uuid")
		}
	}
}

func assertSessionTombstoneOrder(t *testing.T, entries []model.SessionTombstone) {
	t.Helper()

	for i := 1; i < len(entries); i++ {
		prev := entries[i-1]
		curr := entries[i]
		if prev.DeletedAt > curr.DeletedAt {
			t.Fatalf("expected session tombstones ordered by updated_at")
		}
		if prev.DeletedAt == curr.DeletedAt && prev.SessionUUID > curr.SessionUUID {
			t.Fatalf("expected session tombstones ordered by updated_at and session_uuid")
		}
	}
}

func assertMessageTombstoneOrder(t *testing.T, entries []model.MessageTombstone) {
	t.Helper()

	for i := 1; i < len(entries); i++ {
		prev := entries[i-1]
		curr := entries[i]
		if prev.DeletedAt > curr.DeletedAt {
			t.Fatalf("expected message tombstones ordered by updated_at")
		}
		if prev.DeletedAt == curr.DeletedAt && prev.MessageUUID > curr.MessageUUID {
			t.Fatalf("expected message tombstones ordered by updated_at and message_uuid")
		}
	}
}

func TestSessionDiffAndTombstones(t *testing.T) {
	ctx := context.Background()
	repo := &Repository{DB: testDB}

	userID := createTestUser(t)
	t.Cleanup(func() {
		cleanupUser(t, userID)
	})
	ensureKey(t, repo, userID)

	sessionOne := uuid.NewString()
	sessionTwo := uuid.NewString()
	branchMessage := uuid.NewString()

	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:     sessionOne,
		RootSessionUUID: sessionOne,
		EncryptedData:   "enc-1",
		Header:          "hdr-1",
	}); err != nil {
		t.Fatalf("failed to upsert session one: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:           sessionTwo,
		RootSessionUUID:       sessionOne,
		BranchFromMessageUUID: &branchMessage,
		EncryptedData:         "enc-2",
		Header:                "hdr-2",
	}); err != nil {
		t.Fatalf("failed to upsert session two: %v", err)
	}

	diff, err := repo.GetSessionDiff(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch session diff: %v", err)
	}
	if len(diff) != 2 {
		t.Fatalf("expected 2 session diff entries, got %d", len(diff))
	}
	expectedRoots := map[string]string{
		sessionOne: sessionOne,
		sessionTwo: sessionOne,
	}
	expectedBranches := map[string]*string{
		sessionOne: nil,
		sessionTwo: &branchMessage,
	}

	sessionsSeen := map[string]bool{}
	for _, entry := range diff {
		sessionsSeen[entry.SessionUUID] = true

		if expectedRoot, ok := expectedRoots[entry.SessionUUID]; ok {
			if entry.RootSessionUUID != expectedRoot {
				t.Fatalf("expected session %s root uuid %s", entry.SessionUUID, expectedRoot)
			}
		}

		expectedBranch := expectedBranches[entry.SessionUUID]
		if expectedBranch == nil {
			if entry.BranchFromMessageUUID != nil {
				t.Fatalf("expected session %s to have nil branch uuid", entry.SessionUUID)
			}
		} else if entry.BranchFromMessageUUID == nil || *entry.BranchFromMessageUUID != *expectedBranch {
			t.Fatalf("expected session %s branch uuid %s", entry.SessionUUID, *expectedBranch)
		}
	}
	if !sessionsSeen[sessionOne] || !sessionsSeen[sessionTwo] {
		t.Fatalf("expected session diff to include %s and %s", sessionOne, sessionTwo)
	}
	assertSessionDiffOrder(t, diff)

	tombstone, err := repo.DeleteSession(ctx, userID, sessionOne)
	if err != nil {
		t.Fatalf("failed to delete session: %v", err)
	}
	if tombstone.SessionUUID != sessionOne {
		t.Fatalf("unexpected tombstone session uuid: %s", tombstone.SessionUUID)
	}

	tombstones, err := repo.GetSessionTombstones(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch session tombstones: %v", err)
	}
	if len(tombstones) != 1 {
		t.Fatalf("expected 1 session tombstone, got %d", len(tombstones))
	}
	assertSessionTombstoneOrder(t, tombstones)
	if tombstones[0].SessionUUID != sessionOne {
		t.Fatalf("unexpected session tombstone uuid: %s", tombstones[0].SessionUUID)
	}

	diffAfterDelete, err := repo.GetSessionDiff(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch session diff after delete: %v", err)
	}
	if len(diffAfterDelete) != 1 {
		t.Fatalf("expected 1 session diff entry after delete, got %d", len(diffAfterDelete))
	}
	if diffAfterDelete[0].SessionUUID != sessionTwo {
		t.Fatalf("expected remaining session %s, got %s", sessionTwo, diffAfterDelete[0].SessionUUID)
	}
}

func TestMessageDiffAndTombstones(t *testing.T) {
	ctx := context.Background()
	repo := &Repository{DB: testDB}

	userID := createTestUser(t)
	t.Cleanup(func() {
		cleanupUser(t, userID)
	})
	ensureKey(t, repo, userID)

	sessionUUID := uuid.NewString()
	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionUUID,
		EncryptedData: "enc-session",
		Header:        "hdr-session",
	}); err != nil {
		t.Fatalf("failed to upsert session: %v", err)
	}

	messageOne := uuid.NewString()
	attachmentOne := model.AttachmentMeta{
		ID:            uuid.NewString(),
		Size:          123,
		EncryptedName: "enc-name-1",
	}
	if _, err := repo.UpsertMessage(ctx, userID, model.UpsertMessageRequest{
		MessageUUID:       messageOne,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: nil,
		Sender:            "self",
		Attachments:       []model.AttachmentMeta{attachmentOne},
		EncryptedData:     "enc-msg-1",
		Header:            "hdr-msg-1",
	}); err != nil {
		t.Fatalf("failed to upsert message one: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	messageTwo := uuid.NewString()
	attachmentTwo := model.AttachmentMeta{
		ID:            uuid.NewString(),
		Size:          456,
		EncryptedName: "enc-name-2",
	}
	parent := messageOne
	if _, err := repo.UpsertMessage(ctx, userID, model.UpsertMessageRequest{
		MessageUUID:       messageTwo,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: &parent,
		Sender:            "other",
		Attachments:       []model.AttachmentMeta{attachmentTwo},
		EncryptedData:     "enc-msg-2",
		Header:            "hdr-msg-2",
	}); err != nil {
		t.Fatalf("failed to upsert message two: %v", err)
	}

	diff, err := repo.GetMessageDiff(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch message diff: %v", err)
	}
	if len(diff) != 2 {
		t.Fatalf("expected 2 message diff entries, got %d", len(diff))
	}
	entriesByID := map[string]model.MessageDiffEntry{}
	messagesSeen := map[string]bool{}
	for _, entry := range diff {
		messagesSeen[entry.MessageUUID] = true
		entriesByID[entry.MessageUUID] = entry
	}
	if !messagesSeen[messageOne] || !messagesSeen[messageTwo] {
		t.Fatalf("expected message diff to include %s and %s", messageOne, messageTwo)
	}
	assertMessageDiffOrder(t, diff)

	entryOne, ok := entriesByID[messageOne]
	if !ok {
		t.Fatalf("expected message diff to include %s", messageOne)
	}
	if entryOne.Sender != "self" {
		t.Fatalf("expected message one sender self")
	}
	if len(entryOne.Attachments) != 1 {
		t.Fatalf("expected message one attachments length 1")
	}
	if entryOne.Attachments[0].ID != attachmentOne.ID ||
		entryOne.Attachments[0].Size != attachmentOne.Size ||
		entryOne.Attachments[0].EncryptedName != attachmentOne.EncryptedName {
		t.Fatalf("unexpected message one attachment metadata")
	}

	entryTwo, ok := entriesByID[messageTwo]
	if !ok {
		t.Fatalf("expected message diff to include %s", messageTwo)
	}
	if entryTwo.ParentMessageUUID == nil || *entryTwo.ParentMessageUUID != messageOne {
		t.Fatalf("expected message two parent uuid %s", messageOne)
	}
	if entryTwo.Sender != "other" {
		t.Fatalf("expected message two sender other")
	}
	if len(entryTwo.Attachments) != 1 {
		t.Fatalf("expected message two attachments length 1")
	}
	if entryTwo.Attachments[0].ID != attachmentTwo.ID ||
		entryTwo.Attachments[0].Size != attachmentTwo.Size ||
		entryTwo.Attachments[0].EncryptedName != attachmentTwo.EncryptedName {
		t.Fatalf("unexpected message two attachment metadata")
	}

	messageTombstone, err := repo.DeleteMessage(ctx, userID, messageOne)
	if err != nil {
		t.Fatalf("failed to delete message: %v", err)
	}
	if messageTombstone.MessageUUID != messageOne {
		t.Fatalf("unexpected message tombstone uuid: %s", messageTombstone.MessageUUID)
	}

	tombstones, err := repo.GetMessageTombstones(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch message tombstones: %v", err)
	}
	if len(tombstones) != 1 {
		t.Fatalf("expected 1 message tombstone, got %d", len(tombstones))
	}
	assertMessageTombstoneOrder(t, tombstones)
	if tombstones[0].MessageUUID != messageOne {
		t.Fatalf("unexpected message tombstone uuid: %s", tombstones[0].MessageUUID)
	}

	diffAfterDelete, err := repo.GetMessageDiff(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch message diff after delete: %v", err)
	}
	if len(diffAfterDelete) != 1 {
		t.Fatalf("expected 1 message diff entry after delete, got %d", len(diffAfterDelete))
	}
	if diffAfterDelete[0].MessageUUID != messageTwo {
		t.Fatalf("expected remaining message %s, got %s", messageTwo, diffAfterDelete[0].MessageUUID)
	}
}

func TestSessionDiffSinceTimeAndLimit(t *testing.T) {
	ctx := context.Background()
	repo := &Repository{DB: testDB}

	userID := createTestUser(t)
	t.Cleanup(func() {
		cleanupUser(t, userID)
	})
	ensureKey(t, repo, userID)

	sessionOne := uuid.NewString()
	sessionTwo := uuid.NewString()
	sessionThree := uuid.NewString()

	first, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionOne,
		EncryptedData: "enc-1",
		Header:        "hdr-1",
	})
	if err != nil {
		t.Fatalf("failed to upsert session one: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionTwo,
		EncryptedData: "enc-2",
		Header:        "hdr-2",
	}); err != nil {
		t.Fatalf("failed to upsert session two: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionThree,
		EncryptedData: "enc-3",
		Header:        "hdr-3",
	}); err != nil {
		t.Fatalf("failed to upsert session three: %v", err)
	}

	diffAfterFirst, err := repo.GetSessionDiff(ctx, userID, first.UpdatedAt, 10)
	if err != nil {
		t.Fatalf("failed to fetch session diff: %v", err)
	}
	if len(diffAfterFirst) != 2 {
		t.Fatalf("expected 2 session diff entries, got %d", len(diffAfterFirst))
	}
	assertSessionDiffOrder(t, diffAfterFirst)
	sessionsSeen := map[string]bool{}
	for _, entry := range diffAfterFirst {
		sessionsSeen[entry.SessionUUID] = true
	}
	if sessionsSeen[sessionOne] {
		t.Fatalf("expected session diff to exclude %s", sessionOne)
	}
	if !sessionsSeen[sessionTwo] || !sessionsSeen[sessionThree] {
		t.Fatalf("expected session diff to include %s and %s", sessionTwo, sessionThree)
	}

	limited, err := repo.GetSessionDiff(ctx, userID, first.UpdatedAt, 1)
	if err != nil {
		t.Fatalf("failed to fetch limited session diff: %v", err)
	}
	if len(limited) != 1 {
		t.Fatalf("expected 1 session diff entry, got %d", len(limited))
	}
	assertSessionDiffOrder(t, limited)
	if limited[0].SessionUUID == sessionOne {
		t.Fatalf("expected session diff to exclude %s", sessionOne)
	}

	next, err := repo.GetSessionDiff(ctx, userID, limited[0].UpdatedAt, 10)
	if err != nil {
		t.Fatalf("failed to fetch next session diff: %v", err)
	}
	if len(next) != 1 {
		t.Fatalf("expected 1 session diff entry, got %d", len(next))
	}
	if next[0].SessionUUID != sessionThree {
		t.Fatalf("expected remaining session %s, got %s", sessionThree, next[0].SessionUUID)
	}
}

func TestMessageDiffSinceTimeAndLimit(t *testing.T) {
	ctx := context.Background()
	repo := &Repository{DB: testDB}

	userID := createTestUser(t)
	t.Cleanup(func() {
		cleanupUser(t, userID)
	})
	ensureKey(t, repo, userID)

	sessionUUID := uuid.NewString()
	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionUUID,
		EncryptedData: "enc-session",
		Header:        "hdr-session",
	}); err != nil {
		t.Fatalf("failed to upsert session: %v", err)
	}

	messageOne := uuid.NewString()
	first, err := repo.UpsertMessage(ctx, userID, model.UpsertMessageRequest{
		MessageUUID:       messageOne,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: nil,
		Sender:            "self",
		Attachments:       []model.AttachmentMeta{},
		EncryptedData:     "enc-msg-1",
		Header:            "hdr-msg-1",
	})
	if err != nil {
		t.Fatalf("failed to upsert message one: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	messageTwo := uuid.NewString()
	parent := messageOne
	if _, err := repo.UpsertMessage(ctx, userID, model.UpsertMessageRequest{
		MessageUUID:       messageTwo,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: &parent,
		Sender:            "self",
		Attachments:       []model.AttachmentMeta{},
		EncryptedData:     "enc-msg-2",
		Header:            "hdr-msg-2",
	}); err != nil {
		t.Fatalf("failed to upsert message two: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	messageThree := uuid.NewString()
	parent = messageTwo
	if _, err := repo.UpsertMessage(ctx, userID, model.UpsertMessageRequest{
		MessageUUID:       messageThree,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: &parent,
		Sender:            "self",
		Attachments:       []model.AttachmentMeta{},
		EncryptedData:     "enc-msg-3",
		Header:            "hdr-msg-3",
	}); err != nil {
		t.Fatalf("failed to upsert message three: %v", err)
	}

	diffAfterFirst, err := repo.GetMessageDiff(ctx, userID, first.UpdatedAt, 10)
	if err != nil {
		t.Fatalf("failed to fetch message diff: %v", err)
	}
	if len(diffAfterFirst) != 2 {
		t.Fatalf("expected 2 message diff entries, got %d", len(diffAfterFirst))
	}
	assertMessageDiffOrder(t, diffAfterFirst)
	messagesSeen := map[string]bool{}
	for _, entry := range diffAfterFirst {
		messagesSeen[entry.MessageUUID] = true
	}
	if messagesSeen[messageOne] {
		t.Fatalf("expected message diff to exclude %s", messageOne)
	}
	if !messagesSeen[messageTwo] || !messagesSeen[messageThree] {
		t.Fatalf("expected message diff to include %s and %s", messageTwo, messageThree)
	}

	limited, err := repo.GetMessageDiff(ctx, userID, first.UpdatedAt, 1)
	if err != nil {
		t.Fatalf("failed to fetch limited message diff: %v", err)
	}
	if len(limited) != 1 {
		t.Fatalf("expected 1 message diff entry, got %d", len(limited))
	}
	assertMessageDiffOrder(t, limited)
	if limited[0].MessageUUID == messageOne {
		t.Fatalf("expected message diff to exclude %s", messageOne)
	}

	next, err := repo.GetMessageDiff(ctx, userID, limited[0].UpdatedAt, 10)
	if err != nil {
		t.Fatalf("failed to fetch next message diff: %v", err)
	}
	if len(next) != 1 {
		t.Fatalf("expected 1 message diff entry, got %d", len(next))
	}
	if next[0].MessageUUID != messageThree {
		t.Fatalf("expected remaining message %s, got %s", messageThree, next[0].MessageUUID)
	}
}

func TestSessionTombstonesSinceTimeAndLimit(t *testing.T) {
	ctx := context.Background()
	repo := &Repository{DB: testDB}

	userID := createTestUser(t)
	t.Cleanup(func() {
		cleanupUser(t, userID)
	})
	ensureKey(t, repo, userID)

	sessionOne := uuid.NewString()
	sessionTwo := uuid.NewString()

	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionOne,
		EncryptedData: "enc-1",
		Header:        "hdr-1",
	}); err != nil {
		t.Fatalf("failed to upsert session one: %v", err)
	}

	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionTwo,
		EncryptedData: "enc-2",
		Header:        "hdr-2",
	}); err != nil {
		t.Fatalf("failed to upsert session two: %v", err)
	}

	first, err := repo.DeleteSession(ctx, userID, sessionOne)
	if err != nil {
		t.Fatalf("failed to delete session one: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	second, err := repo.DeleteSession(ctx, userID, sessionTwo)
	if err != nil {
		t.Fatalf("failed to delete session two: %v", err)
	}

	tombstones, err := repo.GetSessionTombstones(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch session tombstones: %v", err)
	}
	if len(tombstones) != 2 {
		t.Fatalf("expected 2 session tombstones, got %d", len(tombstones))
	}
	assertSessionTombstoneOrder(t, tombstones)
	sessionsSeen := map[string]bool{}
	for _, entry := range tombstones {
		sessionsSeen[entry.SessionUUID] = true
	}
	if !sessionsSeen[sessionOne] || !sessionsSeen[sessionTwo] {
		t.Fatalf("expected session tombstones to include %s and %s", sessionOne, sessionTwo)
	}

	afterFirst, err := repo.GetSessionTombstones(ctx, userID, first.DeletedAt, 10)
	if err != nil {
		t.Fatalf("failed to fetch session tombstones after sinceTime: %v", err)
	}
	if len(afterFirst) != 1 {
		t.Fatalf("expected 1 session tombstone, got %d", len(afterFirst))
	}
	if afterFirst[0].SessionUUID != second.SessionUUID {
		t.Fatalf("expected remaining session tombstone %s, got %s", second.SessionUUID, afterFirst[0].SessionUUID)
	}

	limited, err := repo.GetSessionTombstones(ctx, userID, 0, 1)
	if err != nil {
		t.Fatalf("failed to fetch limited session tombstones: %v", err)
	}
	if len(limited) != 1 {
		t.Fatalf("expected 1 session tombstone, got %d", len(limited))
	}
	assertSessionTombstoneOrder(t, limited)
}

func TestMessageTombstonesSinceTimeAndLimit(t *testing.T) {
	ctx := context.Background()
	repo := &Repository{DB: testDB}

	userID := createTestUser(t)
	t.Cleanup(func() {
		cleanupUser(t, userID)
	})
	ensureKey(t, repo, userID)

	sessionUUID := uuid.NewString()
	if _, err := repo.UpsertSession(ctx, userID, model.UpsertSessionRequest{
		SessionUUID:   sessionUUID,
		EncryptedData: "enc-session",
		Header:        "hdr-session",
	}); err != nil {
		t.Fatalf("failed to upsert session: %v", err)
	}

	messageOne := uuid.NewString()
	if _, err := repo.UpsertMessage(ctx, userID, model.UpsertMessageRequest{
		MessageUUID:       messageOne,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: nil,
		Sender:            "self",
		Attachments:       []model.AttachmentMeta{},
		EncryptedData:     "enc-msg-1",
		Header:            "hdr-msg-1",
	}); err != nil {
		t.Fatalf("failed to upsert message one: %v", err)
	}

	messageTwo := uuid.NewString()
	parent := messageOne
	if _, err := repo.UpsertMessage(ctx, userID, model.UpsertMessageRequest{
		MessageUUID:       messageTwo,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: &parent,
		Sender:            "self",
		Attachments:       []model.AttachmentMeta{},
		EncryptedData:     "enc-msg-2",
		Header:            "hdr-msg-2",
	}); err != nil {
		t.Fatalf("failed to upsert message two: %v", err)
	}

	first, err := repo.DeleteMessage(ctx, userID, messageOne)
	if err != nil {
		t.Fatalf("failed to delete message one: %v", err)
	}

	time.Sleep(2 * time.Millisecond)

	second, err := repo.DeleteMessage(ctx, userID, messageTwo)
	if err != nil {
		t.Fatalf("failed to delete message two: %v", err)
	}

	tombstones, err := repo.GetMessageTombstones(ctx, userID, 0, 10)
	if err != nil {
		t.Fatalf("failed to fetch message tombstones: %v", err)
	}
	if len(tombstones) != 2 {
		t.Fatalf("expected 2 message tombstones, got %d", len(tombstones))
	}
	assertMessageTombstoneOrder(t, tombstones)
	messagesSeen := map[string]bool{}
	for _, entry := range tombstones {
		messagesSeen[entry.MessageUUID] = true
	}
	if !messagesSeen[messageOne] || !messagesSeen[messageTwo] {
		t.Fatalf("expected message tombstones to include %s and %s", messageOne, messageTwo)
	}

	afterFirst, err := repo.GetMessageTombstones(ctx, userID, first.DeletedAt, 10)
	if err != nil {
		t.Fatalf("failed to fetch message tombstones after sinceTime: %v", err)
	}
	if len(afterFirst) != 1 {
		t.Fatalf("expected 1 message tombstone, got %d", len(afterFirst))
	}
	if afterFirst[0].MessageUUID != second.MessageUUID {
		t.Fatalf("expected remaining message tombstone %s, got %s", second.MessageUUID, afterFirst[0].MessageUUID)
	}

	limited, err := repo.GetMessageTombstones(ctx, userID, 0, 1)
	if err != nil {
		t.Fatalf("failed to fetch limited message tombstones: %v", err)
	}
	if len(limited) != 1 {
		t.Fatalf("expected 1 message tombstone, got %d", len(limited))
	}
	assertMessageTombstoneOrder(t, limited)
}

func TestUpsertAndDeleteIdempotency(t *testing.T) {
	ctx := context.Background()
	repo := &Repository{DB: testDB}

	userID := createTestUser(t)
	t.Cleanup(func() {
		cleanupUser(t, userID)
	})
	ensureKey(t, repo, userID)

	sessionUUID := uuid.NewString()
	sessionReq := model.UpsertSessionRequest{
		SessionUUID:     sessionUUID,
		RootSessionUUID: sessionUUID,
		EncryptedData:   "enc-session",
		Header:          "hdr-session",
	}

	if _, err := repo.UpsertSession(ctx, userID, sessionReq); err != nil {
		t.Fatalf("failed to upsert session: %v", err)
	}
	if _, err := repo.UpsertSession(ctx, userID, sessionReq); err != nil {
		t.Fatalf("failed to re-upsert session: %v", err)
	}

	var count int
	if err := testDB.QueryRow(
		`SELECT COUNT(*) FROM llmchat_sessions WHERE session_uuid = $1 AND user_id = $2`,
		sessionUUID,
		userID,
	).Scan(&count); err != nil {
		t.Fatalf("failed to count sessions: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 session row, got %d", count)
	}

	messageUUID := uuid.NewString()
	messageReq := model.UpsertMessageRequest{
		MessageUUID:       messageUUID,
		SessionUUID:       sessionUUID,
		ParentMessageUUID: nil,
		Sender:            "self",
		Attachments:       []model.AttachmentMeta{},
		EncryptedData:     "enc-msg",
		Header:            "hdr-msg",
	}

	if _, err := repo.UpsertMessage(ctx, userID, messageReq); err != nil {
		t.Fatalf("failed to upsert message: %v", err)
	}
	if _, err := repo.UpsertMessage(ctx, userID, messageReq); err != nil {
		t.Fatalf("failed to re-upsert message: %v", err)
	}

	if err := testDB.QueryRow(
		`SELECT COUNT(*) FROM llmchat_messages WHERE message_uuid = $1 AND user_id = $2`,
		messageUUID,
		userID,
	).Scan(&count); err != nil {
		t.Fatalf("failed to count messages: %v", err)
	}
	if count != 1 {
		t.Fatalf("expected 1 message row, got %d", count)
	}

	sessionTombstone, err := repo.DeleteSession(ctx, userID, sessionUUID)
	if err != nil {
		t.Fatalf("failed to delete session: %v", err)
	}
	sessionTombstoneRepeat, err := repo.DeleteSession(ctx, userID, sessionUUID)
	if err != nil {
		t.Fatalf("failed to re-delete session: %v", err)
	}
	if sessionTombstone.DeletedAt != sessionTombstoneRepeat.DeletedAt {
		t.Fatalf("expected delete session to be idempotent")
	}

	messageTombstone, err := repo.DeleteMessage(ctx, userID, messageUUID)
	if err != nil {
		t.Fatalf("failed to delete message: %v", err)
	}
	messageTombstoneRepeat, err := repo.DeleteMessage(ctx, userID, messageUUID)
	if err != nil {
		t.Fatalf("failed to re-delete message: %v", err)
	}
	if messageTombstone.DeletedAt != messageTombstoneRepeat.DeletedAt {
		t.Fatalf("expected delete message to be idempotent")
	}
}
