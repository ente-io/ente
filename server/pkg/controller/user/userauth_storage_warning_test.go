package user

import (
	"testing"

	"github.com/ente-io/museum/ente"
	logtest "github.com/sirupsen/logrus/hooks/test"
)

func TestAlertStorageWarningDeletionScheduledLoginBlockLogsUserIDAndApp(t *testing.T) {
	hook := logtest.NewGlobal()
	t.Cleanup(hook.Reset)

	(&UserController{}).alertStorageWarningDeletionScheduledLoginBlock(123, ente.Photos)

	entry := hook.LastEntry()
	if entry == nil {
		t.Fatal("expected a log entry")
	}
	if entry.Message != "blocked login due to storage warning scheduled deletion" {
		t.Fatalf("log message = %q, want storage warning login block message", entry.Message)
	}
	if got := entry.Data["user_id"]; got != int64(123) {
		t.Fatalf("user_id field = %v, want 123", got)
	}
	if got := entry.Data["app"]; got != ente.Photos {
		t.Fatalf("app field = %v, want %s", got, ente.Photos)
	}
	if got := entry.Data["code"]; got != StorageWarningDeletionScheduledCode {
		t.Fatalf("code field = %v, want %s", got, StorageWarningDeletionScheduledCode)
	}
}
