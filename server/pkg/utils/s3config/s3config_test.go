package s3config

import (
	"strings"
	"testing"
)

// These tests exercise the small set of helpers that deal with the optional
// per-datacenter key prefix. They avoid the full initialize() path (which
// reads viper and builds S3 clients) and instead manipulate the maps
// directly, which is what the rest of the codebase expects.

func newTestConfig(prefixes map[string]string) *S3Config {
	c := &S3Config{
		bucketPrefixes: map[string]string{},
	}
	for dc, p := range prefixes {
		if p != "" && !strings.HasSuffix(p, "/") {
			p += "/"
		}
		c.bucketPrefixes[dc] = p
	}
	return c
}

func TestGetPrefix(t *testing.T) {
	c := newTestConfig(map[string]string{
		"dc-with":    "ente",
		"dc-without": "",
		"dc-slashed": "ente/",
	})

	if got := c.GetPrefix("dc-with"); got != "ente/" {
		t.Fatalf("expected 'ente/', got %q", got)
	}
	if got := c.GetPrefix("dc-without"); got != "" {
		t.Fatalf("expected empty, got %q", got)
	}
	if got := c.GetPrefix("dc-slashed"); got != "ente/" {
		t.Fatalf("expected 'ente/', got %q", got)
	}
	if got := c.GetPrefix("dc-missing"); got != "" {
		t.Fatalf("expected empty for missing DC, got %q", got)
	}
}

func TestHasPrefix(t *testing.T) {
	cEmpty := newTestConfig(map[string]string{"dc1": "", "dc2": ""})
	if cEmpty.HasPrefix() {
		t.Fatal("expected HasPrefix=false when all prefixes are empty")
	}

	cSome := newTestConfig(map[string]string{"dc1": "", "dc2": "x/"})
	if !cSome.HasPrefix() {
		t.Fatal("expected HasPrefix=true when at least one prefix is set")
	}
}

func TestFullKey(t *testing.T) {
	c := newTestConfig(map[string]string{
		"prefixed":    "ente/",
		"unprefixed":  "",
		"nested":      "photos/backup/",
		"unsanitized": "shared",
	})

	cases := []struct {
		dc, dbKey, want string
	}{
		{"prefixed", "123/abc-uuid", "ente/123/abc-uuid"},
		{"unprefixed", "123/abc-uuid", "123/abc-uuid"},
		{"nested", "7/file-data/42/mldata", "photos/backup/7/file-data/42/mldata"},
		// 'shared' is normalized to 'shared/' on init.
		{"unsanitized", "1/2", "shared/1/2"},
		// Missing DC should behave like empty prefix.
		{"missing", "1/2", "1/2"},
	}

	for _, tc := range cases {
		if got := c.FullKey(tc.dc, tc.dbKey); got != tc.want {
			t.Errorf("FullKey(%q, %q) = %q, want %q", tc.dc, tc.dbKey, got, tc.want)
		}
	}
}

func TestStripPrefix(t *testing.T) {
	c := newTestConfig(map[string]string{
		"prefixed":   "ente/",
		"unprefixed": "",
	})

	if got := c.StripPrefix("prefixed", "ente/123/x"); got != "123/x" {
		t.Errorf("expected '123/x', got %q", got)
	}

	// Key without the expected prefix is returned verbatim. This is the
	// defensive behavior: if something slipped into the bucket outside the
	// prefix, we return the key unchanged rather than corrupting it.
	if got := c.StripPrefix("prefixed", "something-else/1/2"); got != "something-else/1/2" {
		t.Errorf("expected key unchanged when prefix missing, got %q", got)
	}

	// Unprefixed DC is a no-op.
	if got := c.StripPrefix("unprefixed", "123/x"); got != "123/x" {
		t.Errorf("expected '123/x', got %q", got)
	}
}

func TestRoundtripFullStripPrefix(t *testing.T) {
	c := newTestConfig(map[string]string{"a": "ente/", "b": ""})

	for _, dc := range []string{"a", "b"} {
		db := "42/uuid-xyz"
		roundtripped := c.StripPrefix(dc, c.FullKey(dc, db))
		if roundtripped != db {
			t.Errorf("dc=%s: StripPrefix(FullKey(%q)) = %q", dc, db, roundtripped)
		}
	}
}

func TestValidateDBKey(t *testing.T) {
	c := newTestConfig(nil)

	if !c.ValidateDBKey("42/anything", 42) {
		t.Error("expected valid key to pass")
	}
	if c.ValidateDBKey("43/anything", 42) {
		t.Error("expected wrong-user key to fail")
	}
	if c.ValidateDBKey("42-suffix/x", 42) {
		t.Error("expected userID-prefix without trailing slash to fail")
	}
	if c.ValidateDBKey("", 42) {
		t.Error("expected empty key to fail")
	}
}

func TestNewDBObjectKey(t *testing.T) {
	c := newTestConfig(nil)

	key := c.NewDBObjectKey(123)
	if !strings.HasPrefix(key, "123/") {
		t.Errorf("expected key to start with '123/', got %q", key)
	}
	if !c.ValidateDBKey(key, 123) {
		t.Errorf("expected newly generated key to validate, got %q", key)
	}
	// Two invocations must produce different keys (UUID randomness).
	other := c.NewDBObjectKey(123)
	if key == other {
		t.Error("expected distinct keys from consecutive NewDBObjectKey calls")
	}
}
