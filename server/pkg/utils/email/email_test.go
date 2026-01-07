package email

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetMaskedEmailForPublic(t *testing.T) {
	tests := []struct {
		name     string
		email    string
		expected string
	}{
		{
			name:     "standard email",
			email:    "john@example.io",
			expected: "jo**@e********o",
		},
		{
			name:     "gmail address",
			email:    "john.doe@gmail.com",
			expected: "jo******@g*******m",
		},
		{
			name:     "short username 2 chars",
			email:    "ab@example.com",
			expected: "ab@e*********m",
		},
		{
			name:     "short username 1 char",
			email:    "a@example.com",
			expected: "a@e*********m",
		},
		{
			name:     "short domain 2 chars",
			email:    "test@ab",
			expected: "te**@ab",
		},
		{
			name:     "short domain 1 char",
			email:    "test@a",
			expected: "te**@a",
		},
		{
			name:     "email with spaces trimmed",
			email:    "  user@domain.com  ",
			expected: "us**@d********m",
		},
		{
			name:     "invalid email no @",
			email:    "invalidemail",
			expected: "[invalid_email]",
		},
		{
			name:     "invalid email @ at start",
			email:    "@domain.com",
			expected: "[invalid_email]",
		},
		{
			name:     "invalid email @ at end",
			email:    "user@",
			expected: "[invalid_email]",
		},
		{
			name:     "empty string",
			email:    "",
			expected: "[invalid_email]",
		},
		{
			name:     "long username and domain",
			email:    "verylongusername@verylongdomain.org",
			expected: "ve**************@v****************g",
		},
		{
			name:     "unicode username",
			email:    "用户名@example.com",
			expected: "用户*@e*********m",
		},
		{
			name:     "unicode domain",
			email:    "test@例え.jp",
			expected: "te**@例***p",
		},
		{
			name:     "mixed unicode",
			email:    "日本語@ドメイン.jp",
			expected: "日本*@ド*****p",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := GetMaskedEmailForPublic(tt.email)
			assert.Equal(t, tt.expected, result)
		})
	}
}
