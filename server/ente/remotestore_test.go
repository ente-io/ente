package ente

import "testing"

func TestIsValidDomainWithoutScheme(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		wantErr bool
	}{
		// ✅ Valid cases
		{"simple domain", "google.com", false},
		{"multi-level domain", "sub.example.co.in", false},
		{"numeric in label", "a1b2c3.com", false},
		{"long but valid label", "my-very-long-subdomain-name.example.com", false},

		// ❌ Leading/trailing spaces
		{"leading space", " google.com", true},
		{"trailing space", "google.com ", true},
		{"both spaces", " google.com ", true},

		// ❌ Empty or whitespace
		{"empty string", "", true},
		{"only spaces", "   ", true},

		// ❌ Scheme included
		{"http scheme", "http://google.com", true},
		{"https scheme", "https://example.com", true},
		{"ftp scheme", "ftp://example.com", true},

		// ❌ Invalid characters
		{"underscore in label", "my_domain.com", true},
		{"invalid symbol", "exa$mple.com", true},
		{"space inside", "exa mple.com", true},

		// ❌ Wrong format
		{"missing dot", "localhost", true},
		{"single label TLD", "com", true},
		{"ends with dot", "example.com.", true},
		{"ends with dash", "example-.com", true},
		{"starts with dash", "-example.com", true},

		// ❌ Consecutive dots
		{"double dots", "example..com", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := isValidDomainWithoutScheme(tt.input)
			if (err != nil) != tt.wantErr {
				t.Errorf("isValidDomainWithoutScheme(%q) error = %v, wantErr %v", tt.input, err, tt.wantErr)
			}
		})
	}
}

func TestFlagKey_IsValidValue(t *testing.T) {
	tests := []struct {
		name    string
		key     FlagKey
		value   string
		wantErr bool
	}{
		// ✅ Valid boolean flag values
		{"valid true for bool key", MapEnabled, "true", false},
		{"valid false for bool key", FaceSearchEnabled, "false", false},

		// ❌ Invalid boolean flag values
		{"invalid value for bool key", PassKeyEnabled, "yes", true},
		{"empty value for bool key", IsInternalUser, "", true},

		// ✅ Valid custom domain values
		{"valid custom domain", CustomDomain, "example.com", false},
		{"valid subdomain", CustomDomain, "sub.example.com", false},

		// ❌ Invalid custom domain values
		{"empty custom domain", CustomDomain, "", false}, // Allowed as empty
		{"custom domain with scheme", CustomDomain, "http://example.com", true},
		{"custom domain with invalid format", CustomDomain, "exa$mple.com", true},
		{"custom domain with leading space", CustomDomain, " example.com", true},
		{"custom domain with trailing space", CustomDomain, "example.com ", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.key.IsValidValue(tt.value)
			if (err != nil) != tt.wantErr {
				t.Errorf("FlagKey(%q).IsValidValue(%q) error = %v, wantErr %v", tt.key, tt.value, err, tt.wantErr)
			}
		})
	}
}
