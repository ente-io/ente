package email

import (
	"testing"

	"github.com/ente-io/museum/internal/testutil"
	"github.com/stretchr/testify/assert"
)

func TestStorageWarningTemplatesIncludeAccountEmail(t *testing.T) {
	testutil.WithServerRoot(t)

	templateData := map[string]interface{}{
		"AccountEmail":   "alerts@example.com",
		"AutoDeleteDate": "April 1, 2026",
		"ExpiryDate":     "March 1, 2026",
	}
	templateNames := []string{
		"storage-warning/storage_warning_active_overage.html",
		"storage-warning/storage_warning_expired.html",
	}

	for _, templateName := range templateNames {
		t.Run(templateName, func(t *testing.T) {
			body, err := getMailBodyWithBase("base.html", templateName, templateData)
			assert.NoError(t, err)
			assert.Contains(t, body, "alerts@example.com")
		})
	}
}
