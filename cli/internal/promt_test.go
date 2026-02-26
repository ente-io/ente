package internal

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolvePath(t *testing.T) {
	// Get current working directory for testing relative paths
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current working directory: %v", err)
	}

	// Get home directory for testing ~ expansion
	home, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("Failed to get home directory: %v", err)
	}

	tests := []struct {
		name        string
		input       string
		expected    string
		expectError bool
	}{
		{
			name:        "current directory dot",
			input:       ".",
			expected:    cwd,
			expectError: false,
		},
		{
			name:        "tilde only",
			input:       "~",
			expected:    home,
			expectError: false,
		},
		{
			name:        "tilde with slash",
			input:       "~/",
			expected:    home,
			expectError: false,
		},
		{
			name:        "tilde with subdirectory",
			input:       "~/Documents",
			expected:    filepath.Join(home, "Documents"),
			expectError: false,
		},
		{
			name:        "tilde with nested path",
			input:       "~/Documents/test/file.txt",
			expected:    filepath.Join(home, "Documents", "test", "file.txt"),
			expectError: false,
		},
		{
			name:        "relative path",
			input:       "test/dir",
			expected:    filepath.Join(cwd, "test", "dir"),
			expectError: false,
		},
		{
			name:        "parent directory",
			input:       "..",
			expected:    filepath.Dir(cwd),
			expectError: false,
		},
		{
			name:        "parent with subdirectory",
			input:       "../sibling",
			expected:    filepath.Join(filepath.Dir(cwd), "sibling"),
			expectError: false,
		},
		{
			name:        "cleaned path",
			input:       "/tmp/../test",
			expected:    "/test",
			expectError: false,
		},
		{
			name:        "absolute path unchanged",
			input:       "/tmp/test",
			expected:    "/tmp/test",
			expectError: false,
		},
		{
			name:        "empty string",
			input:       "",
			expected:    cwd,
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := ResolvePath(tt.input)

			if tt.expectError {
				if err == nil {
					t.Errorf("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			// Clean both paths for comparison to handle path separator differences
			expectedClean := filepath.Clean(tt.expected)
			resultClean := filepath.Clean(result)

			if resultClean != expectedClean {
				t.Errorf("Expected %q, got %q", expectedClean, resultClean)
			}

			// Verify the result is an absolute path
			if !filepath.IsAbs(result) {
				t.Errorf("Result %q is not an absolute path", result)
			}
		})
	}
}
