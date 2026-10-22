package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/ente/cli/utils/constants"
	"github.com/spf13/viper"
	"github.com/zalando/go-keyring"
)

func TestCLIStartup(t *testing.T) {
	if args := os.Getenv("ENTE_CLI_TEST_ARGS"); args != "" {
		keyring.MockInit()
		if os.Getenv("ENTE_CLI_TEST_NO_KEYRING") != "" {
			keyring.MockInitWithError(errors.New("unexpected keyring access"))
		}
		var command []string
		if err := json.Unmarshal([]byte(args), &command); err != nil {
			t.Fatal(err)
		}
		os.Args = append([]string{"ente"}, command...)
		main()
		return
	}

	var requests atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests.Add(1)
		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer server.Close()
	tests := []struct {
		name       string
		args       []string
		wantError  string
		wantOutput string
		keyring    bool
		config     string
		noConfig   bool
	}{
		{name: "export", args: []string{"export"}, wantError: "refusing network command"},
		{name: "default endpoint", args: []string{"export"}, wantError: "refusing network command", noConfig: true},
		{name: "login", args: []string{"account", "add"}, wantError: "refusing network command"},
		{name: "list users", args: []string{"admin", "list-users"}, wantError: "refusing network command"},
		{name: "get user", args: []string{"admin", "get-user-id", "--user", "user@example.invalid"}, wantError: "refusing network command"},
		{name: "disable 2fa", args: []string{"admin", "disable-2fa", "--user", "user@example.invalid"}, wantError: "refusing network command"},
		{name: "disable passkey", args: []string{"admin", "disable-passkey", "--user", "user@example.invalid"}, wantError: "refusing network command"},
		{name: "delete user", args: []string{"admin", "delete-user", "--user", "user@example.invalid"}, wantError: "refusing network command"},
		{name: "subscription", args: []string{"admin", "update-subscription", "--user", "user@example.invalid"}, wantError: "refusing network command"},
		{name: "send mail", args: []string{"admin", "send-mail", "to@example.invalid", "from@example.invalid", "Test"}, wantError: "refusing network command"},
		{name: "version", args: []string{"version"}, wantOutput: "Version"},
		{name: "export help", args: []string{"export", "--help"}, wantOutput: "Usage:"},
		{name: "login help", args: []string{"account", "add", "--help"}, wantOutput: "Usage:"},
		{name: "admin help", args: []string{"admin", "list-users", "--help"}, wantOutput: "Usage:"},
		{name: "completion", args: []string{"completion", "bash"}, wantOutput: "bash completion"},
		{name: "list accounts", args: []string{"account", "list"}, wantOutput: "Configured accounts: 0", keyring: true},
		{name: "get token", args: []string{"account", "get-token", "--email", "missing@example.invalid"}, wantOutput: "account not found", keyring: true},
		{name: "update account", args: []string{"account", "update", "--email", "missing@example.invalid", "--dir", "."}, wantOutput: "account not found", keyring: true},
		{name: "decrypt", args: []string{"auth", "decrypt", "missing", "output"}, wantError: "error reading file"},
		{name: "invalid trusted YAML", args: []string{"export"}, wantError: "cannot load trusted configuration", config: "endpoint: [secret-sentinel"},
		{name: "invalid trusted endpoint", args: []string{"export"}, wantError: "invalid endpoint.api", config: "endpoint:\n  api: []\n"},
		{name: "null trusted endpoint", args: []string{"export"}, wantError: "invalid endpoint.api", config: "endpoint:\n  api: null\n"},
		{name: "null trusted endpoint section", args: []string{"export"}, wantError: "invalid endpoint.api", config: "endpoint: null\n"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			root := t.TempDir()
			home := filepath.Join(root, "home")
			cwd := filepath.Join(root, "cwd")
			body := tt.config
			if body == "" {
				body = "endpoint:\n  api: " + server.URL + "\n"
			}
			if !tt.noConfig {
				writeTestConfig(t, filepath.Join(home, ".ente", "config.yaml"), body)
			}
			writeTestConfig(t, filepath.Join(cwd, "config.yaml"), "not valid YAML: [secret-sentinel")
			args, err := json.Marshal(tt.args)
			if err != nil {
				t.Fatal(err)
			}
			executable, err := os.Executable()
			if err != nil {
				t.Fatal(err)
			}
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			command := exec.CommandContext(ctx, executable, "-test.run=^TestCLIStartup$")
			command.Dir = cwd
			command.Env = append(os.Environ(),
				"HOME="+home, "USERPROFILE="+home,
				"ENTE_CLI_CONFIG_DIR=", "ENTE_CLI_CONFIG_PATH=",
				"ENTE_CLI_SECRETS_PATH=",
				"ENTE_CLI_TMP_PATH="+root,
				"ENTE_CLI_TEST_ARGS="+string(args), "ENTE_CLI_TEST_NO_KEYRING=",
			)
			if !tt.keyring {
				command.Env = append(command.Env, "ENTE_CLI_TEST_NO_KEYRING=1")
			}
			var stdout, stderr bytes.Buffer
			command.Stdout, command.Stderr = &stdout, &stderr
			err = command.Run()
			if tt.wantError != "" {
				if err == nil || !strings.Contains(stderr.String(), tt.wantError) || stdout.Len() != 0 {
					t.Fatalf("error=%v stdout=%q stderr=%q", err, stdout.String(), stderr.String())
				}
			} else if err != nil || !strings.Contains(stdout.String(), tt.wantOutput) {
				t.Fatalf("error=%v stdout=%q stderr=%q", err, stdout.String(), stderr.String())
			}
			if strings.Contains(stderr.String(), "secret-sentinel") || strings.Contains(stderr.String(), "unexpected keyring access") {
				t.Fatalf("unsafe startup: %s", stderr.String())
			}
		})
	}
	if got := requests.Load(); got != 0 {
		t.Fatalf("received %d unexpected network requests", got)
	}
}

func TestInvalidTrustedConfig(t *testing.T) {
	for name, body := range map[string]string{
		"malformed YAML":        "endpoint: [secret-sentinel",
		"endpoint list":         "endpoint:\n  api: []\n",
		"empty endpoint":        "endpoint:\n  api: ''\n",
		"null endpoint":         "endpoint:\n  api: null\n",
		"null endpoint section": "endpoint: null\n",
		"endpoint object":       "endpoint:\n  api: {}\n",
		"TOML":                  "[endpoint]\napi = 'secret-sentinel'\n",
	} {
		t.Run(name, func(t *testing.T) {
			viper.Reset()
			dir := t.TempDir()
			writeTestConfig(t, filepath.Join(dir, "config.yaml"), body)
			err := initConfig(dir)
			if err == nil || strings.Contains(err.Error(), "secret-sentinel") {
				t.Fatalf("expected sanitized configuration error, got %v", err)
			}
		})
	}
	t.Cleanup(viper.Reset)
}

func TestTrustedConfigSymlink(t *testing.T) {
	for name, exists := range map[string]bool{"missing target": false, "existing target": true} {
		t.Run(name, func(t *testing.T) {
			viper.Reset()
			dir := t.TempDir()
			target := filepath.Join(t.TempDir(), "settings.yaml")
			if exists {
				writeTestConfig(t, target, "endpoint:\n  api: https://trusted.invalid\n")
			}
			if err := os.Symlink(target, filepath.Join(dir, "config.yaml")); err != nil {
				t.Skipf("file symlinks unavailable: %v", err)
			}
			err := initConfig(dir)
			if !exists {
				if err == nil || !strings.Contains(err.Error(), "cannot inspect trusted configuration") {
					t.Fatalf("expected configuration error, got %v", err)
				}
			} else if err != nil || viper.GetString("endpoint.api") != "https://trusted.invalid" {
				t.Fatalf("linked configuration not loaded: %v", err)
			}
		})
	}
	t.Cleanup(viper.Reset)
}

func TestTrustedConfigWithoutEndpoint(t *testing.T) {
	viper.Reset()
	t.Cleanup(viper.Reset)
	dir := t.TempDir()
	writeTestConfig(t, filepath.Join(dir, "config.yaml"), "log:\n  http: true\n")
	if err := initConfig(dir); err != nil {
		t.Fatal(err)
	}
	if viper.GetString("endpoint.api") != constants.EnteApiUrl || !viper.GetBool("log.http") {
		t.Fatal("configuration without an endpoint did not retain the default API")
	}
}

func TestWorkingDirectoryConfig(t *testing.T) {
	for _, name := range []string{"config.yaml", "config.json", "config.toml", "config"} {
		t.Run(name, func(t *testing.T) {
			cwd, trusted := t.TempDir(), t.TempDir()
			t.Chdir(cwd)
			writeTestConfig(t, filepath.Join(cwd, name), "not valid YAML: [secret-sentinel")
			err := checkWorkingDirectoryConfig(trusted)
			if err == nil || !strings.Contains(err.Error(), "refusing network command") || strings.Contains(err.Error(), "secret-sentinel") {
				t.Fatalf("expected migration error, got %v", err)
			}
		})
	}
	t.Run("same directory", func(t *testing.T) {
		cwd := t.TempDir()
		t.Chdir(cwd)
		writeTestConfig(t, filepath.Join(cwd, "config.yaml"), "endpoint:\n  api: https://trusted.invalid\n")
		alias := filepath.Join(t.TempDir(), "alias")
		if err := os.Symlink(cwd, alias); err != nil {
			t.Skipf("directory symlinks unavailable: %v", err)
		}
		for _, dir := range []string{".", "./", cwd, alias} {
			if err := checkWorkingDirectoryConfig(dir); err != nil {
				t.Fatalf("trusted directory %q: %v", dir, err)
			}
		}
	})
	t.Run("no configuration file", func(t *testing.T) {
		cwd := t.TempDir()
		t.Chdir(cwd)
		if err := os.Mkdir("config.yaml", 0700); err != nil {
			t.Fatal(err)
		}
		if err := checkWorkingDirectoryConfig(t.TempDir()); err != nil {
			t.Fatal(err)
		}
	})
}

func TestConfigDirectoryRoot(t *testing.T) {
	dir := filepath.VolumeName(t.TempDir()) + string(filepath.Separator)
	t.Setenv("ENTE_CLI_CONFIG_DIR", dir)
	got, err := GetCLIConfigDir()
	if err != nil || got != dir {
		t.Fatalf("config directory = %q, %v; want %q", got, err, dir)
	}
}

func writeTestConfig(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0600); err != nil {
		t.Fatal(err)
	}
}
