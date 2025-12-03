package crypto

import (
	"encoding/base64"
	"fmt"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test real-world scenarios based on codebase usage

func TestRealWorldEmailEncryption(t *testing.T) {
	// Simulating email encryption as used in user controller
	secretEncryptionKey := generateTestKey()

	emails := []string{
		"user@example.com",
		"test.user+tag@example.co.uk",
		"admin@subdomain.example.org",
		"user.name-123@company-name.io",
		// Edge cases found in production
		"UPPERCASE@EXAMPLE.COM",
		"mixed.Case@Example.Com",
		"user@例え.jp", // IDN domain
		"very.long.email.address.with.many.dots@subdomain.of.a.domain.example.com",
	}

	for _, email := range emails {
		t.Run(fmt.Sprintf("email_%s", strings.ReplaceAll(email, "@", "_at_")), func(t *testing.T) {
			// Test with libsodium
			encryptedLib, err := Encrypt(email, secretEncryptionKey)
			require.NoError(t, err)

			// Test with native
			encryptedNative, err := EncryptNative(email, secretEncryptionKey)
			require.NoError(t, err)

			// Cross-decrypt
			decryptedFromLib, err := DecryptNative(encryptedLib.Cipher, secretEncryptionKey, encryptedLib.Nonce)
			require.NoError(t, err)
			assert.Equal(t, email, decryptedFromLib)

			decryptedFromNative, err := Decrypt(encryptedNative.Cipher, secretEncryptionKey, encryptedNative.Nonce)
			require.NoError(t, err)
			assert.Equal(t, email, decryptedFromNative)
		})
	}
}

func TestRealWorldSecretEncryption(t *testing.T) {
	// Simulating 2FA secret encryption as used in twofactor controller
	secretEncryptionKey := generateTestKey()

	secrets := []string{
		"JBSWY3DPEHPK3PXP", // Standard TOTP secret
		"MFRGGZDFMZTWQ2LKNNWG23TPOBYXE43UOV3HO6DZPF4GIZLDOQWXI", // Longer secret
		"abcdefghijklmnopqrstuvwxyz234567",                      // Base32 alphabet
		"ABCDEFGHIJKLMNOP",                                      // Short secret
		strings.Repeat("A", 256),                                // Large secret
	}

	for _, secret := range secrets {
		t.Run(fmt.Sprintf("secret_len_%d", len(secret)), func(t *testing.T) {
			// Encrypt with both implementations
			encryptedLib, err := Encrypt(secret, secretEncryptionKey)
			require.NoError(t, err)

			encryptedNative, err := EncryptNative(secret, secretEncryptionKey)
			require.NoError(t, err)

			// Verify both can decrypt each other
			decryptedLib, err := Decrypt(encryptedNative.Cipher, secretEncryptionKey, encryptedNative.Nonce)
			require.NoError(t, err)
			assert.Equal(t, secret, decryptedLib)

			decryptedNative, err := DecryptNative(encryptedLib.Cipher, secretEncryptionKey, encryptedLib.Nonce)
			require.NoError(t, err)
			assert.Equal(t, secret, decryptedNative)
		})
	}
}

func TestRealWorldHashingWithKey(t *testing.T) {
	// Simulating email and secret hashing as used in the codebase
	hashingKeys := [][]byte{
		nil,                             // Some hashes use nil key
		generateTestKey(),               // 32-byte key
		[]byte("sixteen-byte-key"),      // 16-byte key (minimum for libsodium)
		[]byte(strings.Repeat("x", 64)), // 64-byte key (maximum for libsodium)
	}

	inputs := []string{
		"user@example.com",
		"test.user@example.com",
		strings.ToLower("Admin@Example.COM"), // Email normalization
		"JBSWY3DPEHPK3PXP",                   // TOTP secret
		"",                                   // Edge case - empty string (skip for libsodium due to bug)
		strings.Repeat("a", 10000),           // Large input
	}

	for _, key := range hashingKeys {
		keyName := "nil"
		if key != nil {
			keyName = fmt.Sprintf("key_len_%d", len(key))
		}

		for _, input := range inputs {
			if input == "" {
				continue // Skip empty string due to libsodium-go bug
			}

			t.Run(fmt.Sprintf("%s_input_%d_chars", keyName, len(input)), func(t *testing.T) {
				hashLib, err := GetHash(input, key)
				require.NoError(t, err)

				hashNative, err := GetHashNative(input, key)
				require.NoError(t, err)

				assert.Equal(t, hashLib, hashNative, "Hashes should match")

				// Verify hash is deterministic
				hashLib2, err := GetHash(input, key)
				require.NoError(t, err)
				assert.Equal(t, hashLib, hashLib2, "Hash should be deterministic")

				hashNative2, err := GetHashNative(input, key)
				require.NoError(t, err)
				assert.Equal(t, hashNative, hashNative2, "Native hash should be deterministic")
			})
		}
	}
}

func TestRealWorldTokenEncryption(t *testing.T) {
	// Simulating token encryption with public keys as used in auth

	// Generate test public keys
	publicKey1 := make([]byte, 32)
	for i := range publicKey1 {
		publicKey1[i] = byte(i + 1)
	}

	publicKey2 := make([]byte, 32)
	for i := range publicKey2 {
		publicKey2[i] = byte(i * 2)
	}

	publicKeys := []string{
		base64.StdEncoding.EncodeToString(publicKey1),
		base64.StdEncoding.EncodeToString(publicKey2),
	}

	tokens := []string{
		// JWT-like tokens
		base64.URLEncoding.EncodeToString([]byte("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")),
		// Session tokens
		base64.URLEncoding.EncodeToString([]byte("session_1234567890")),
		// Random tokens
		base64.URLEncoding.EncodeToString([]byte(strings.Repeat("x", 64))),
	}

	for _, publicKey := range publicKeys {
		for i, token := range tokens {
			t.Run(fmt.Sprintf("token_%d", i), func(t *testing.T) {
				// Both implementations should produce valid sealed boxes
				encryptedLib, err := GetEncryptedToken(token, publicKey)
				require.NoError(t, err)

				encryptedNative, err := GetEncryptedTokenNative(token, publicKey)
				require.NoError(t, err)

				// Verify format (ephemeral public key + ciphertext)
				encryptedLibBytes, err := base64.StdEncoding.DecodeString(encryptedLib)
				require.NoError(t, err)
				assert.GreaterOrEqual(t, len(encryptedLibBytes), 48, "Should have ephemeral key (32) + MAC (16)")

				encryptedNativeBytes, err := base64.StdEncoding.DecodeString(encryptedNative)
				require.NoError(t, err)
				assert.GreaterOrEqual(t, len(encryptedNativeBytes), 48, "Should have ephemeral key (32) + MAC (16)")
			})
		}
	}
}

func TestMigrationScenarios(t *testing.T) {
	// Test scenarios for migrating from libsodium to native

	t.Run("existing_encrypted_data_compatibility", func(t *testing.T) {
		// Simulate existing data encrypted with libsodium
		data := "existing.user@example.com"
		key := generateTestKey()

		// Encrypt with libsodium (simulating existing data)
		existingEncrypted, err := Encrypt(data, key)
		require.NoError(t, err)

		// Ensure native can decrypt existing data
		decrypted, err := DecryptNative(existingEncrypted.Cipher, key, existingEncrypted.Nonce)
		require.NoError(t, err)
		assert.Equal(t, data, decrypted, "Native should decrypt existing libsodium data")
	})

	t.Run("new_data_backward_compatibility", func(t *testing.T) {
		// Simulate new data encrypted with native
		data := "new.user@example.com"
		key := generateTestKey()

		// Encrypt with native (new implementation)
		newEncrypted, err := EncryptNative(data, key)
		require.NoError(t, err)

		// Ensure libsodium can still decrypt if needed
		decrypted, err := Decrypt(newEncrypted.Cipher, key, newEncrypted.Nonce)
		require.NoError(t, err)
		assert.Equal(t, data, decrypted, "Libsodium should decrypt native encrypted data")
	})

	t.Run("hash_consistency_across_migration", func(t *testing.T) {
		// Critical for email lookups and authentication
		email := "critical.user@example.com"
		hashingKey := []byte("production-hashing-key-32-bytes!")

		// Hash with both implementations
		hashLib, err := GetHash(email, hashingKey)
		require.NoError(t, err)

		hashNative, err := GetHashNative(email, hashingKey)
		require.NoError(t, err)

		// MUST be identical for database lookups to work
		assert.Equal(t, hashLib, hashNative, "Hashes must be identical for migration")
	})
}

func TestProductionEdgeCases(t *testing.T) {
	key := generateTestKey()

	t.Run("unicode_data", func(t *testing.T) {
		// Test with various unicode strings
		unicodeStrings := []string{
			"Hello 世界 🌍",
			"Здравствуй мир",
			"مرحبا بالعالم",
			"🔐🔑🗝️",
			"user@日本.jp",
		}

		for _, s := range unicodeStrings {
			encLib, err := Encrypt(s, key)
			require.NoError(t, err)

			encNative, err := EncryptNative(s, key)
			require.NoError(t, err)

			// Cross-decrypt
			decLib, err := DecryptNative(encLib.Cipher, key, encLib.Nonce)
			require.NoError(t, err)
			assert.Equal(t, s, decLib)

			decNative, err := Decrypt(encNative.Cipher, key, encNative.Nonce)
			require.NoError(t, err)
			assert.Equal(t, s, decNative)
		}
	})

	t.Run("binary_data", func(t *testing.T) {
		// Test with binary data (non-UTF8)
		binaryData := []string{
			string([]byte{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}),
			string([]byte{255, 254, 253, 252, 251}),
			"\x00\x01\x02\x03",
		}

		for _, data := range binaryData {
			encLib, err := Encrypt(data, key)
			require.NoError(t, err)

			encNative, err := EncryptNative(data, key)
			require.NoError(t, err)

			// Both should handle binary data correctly
			decLib, err := DecryptNative(encLib.Cipher, key, encLib.Nonce)
			require.NoError(t, err)
			assert.Equal(t, data, decLib)

			decNative, err := Decrypt(encNative.Cipher, key, encNative.Nonce)
			require.NoError(t, err)
			assert.Equal(t, data, decNative)
		}
	})

	t.Run("very_large_data", func(t *testing.T) {
		// Test with large data (e.g., large JSON payloads)
		sizes := []int{
			10 * 1024,   // 10KB
			100 * 1024,  // 100KB
			1024 * 1024, // 1MB
		}

		for _, size := range sizes {
			t.Run(fmt.Sprintf("size_%d", size), func(t *testing.T) {
				largeData := strings.Repeat("a", size)

				// Encrypt with native (faster based on benchmarks)
				encNative, err := EncryptNative(largeData, key)
				require.NoError(t, err)

				// Decrypt with libsodium to verify compatibility
				decLib, err := Decrypt(encNative.Cipher, key, encNative.Nonce)
				require.NoError(t, err)
				assert.Equal(t, largeData, decLib)
			})
		}
	})
}

func TestConcurrentOperations(t *testing.T) {
	// Test thread-safety of both implementations
	key := generateTestKey()
	hashKey := []byte("concurrent-hash-key-test-32byte!")

	t.Run("concurrent_encryption", func(t *testing.T) {
		data := []string{
			"user1@example.com",
			"user2@example.com",
			"user3@example.com",
			"user4@example.com",
			"user5@example.com",
		}

		// Run concurrent encryptions
		results := make(chan bool, len(data)*2)

		for _, d := range data {
			go func(text string) {
				enc, err := EncryptNative(text, key)
				assert.NoError(t, err)
				dec, err := DecryptNative(enc.Cipher, key, enc.Nonce)
				assert.NoError(t, err)
				results <- (dec == text)
			}(d)

			go func(text string) {
				enc, err := Encrypt(text, key)
				assert.NoError(t, err)
				dec, err := Decrypt(enc.Cipher, key, enc.Nonce)
				assert.NoError(t, err)
				results <- (dec == text)
			}(d)
		}

		// Verify all succeeded
		for i := 0; i < len(data)*2; i++ {
			assert.True(t, <-results)
		}
	})

	t.Run("concurrent_hashing", func(t *testing.T) {
		inputs := []string{
			"hash1@example.com",
			"hash2@example.com",
			"hash3@example.com",
		}

		results := make(chan string, len(inputs)*2)

		for _, input := range inputs {
			go func(text string) {
				hash, err := GetHashNative(text, hashKey)
				assert.NoError(t, err)
				results <- hash
			}(input)

			go func(text string) {
				hash, err := GetHash(text, hashKey)
				assert.NoError(t, err)
				results <- hash
			}(input)
		}

		// Collect and verify consistency
		hashes := make(map[string]int)
		for i := 0; i < len(inputs)*2; i++ {
			h := <-results
			hashes[h]++
		}

		// Each input should produce the same hash twice (once from each impl)
		for _, count := range hashes {
			assert.Equal(t, 2, count, "Each hash should appear exactly twice")
		}
	})
}

func TestDeterministicBehavior(t *testing.T) {
	// Critical test: Ensure deterministic behavior with same nonce
	key := generateTestKey()
	data := "deterministic.test@example.com"

	// Use a fixed nonce for testing
	fixedNonce := make([]byte, SecretBoxNonceBytes)
	for i := range fixedNonce {
		fixedNonce[i] = byte(i * 3)
	}

	// Encrypt multiple times with same nonce
	enc1, err := encryptWithNonce(data, key, fixedNonce)
	require.NoError(t, err)

	enc2, err := encryptWithNonce(data, key, fixedNonce)
	require.NoError(t, err)

	encNative1, err := encryptWithNonceNative(data, key, fixedNonce)
	require.NoError(t, err)

	encNative2, err := encryptWithNonceNative(data, key, fixedNonce)
	require.NoError(t, err)

	// All should be identical
	assert.Equal(t, enc1.Cipher, enc2.Cipher, "Libsodium should be deterministic with same nonce")
	assert.Equal(t, encNative1.Cipher, encNative2.Cipher, "Native should be deterministic with same nonce")
	assert.Equal(t, enc1.Cipher, encNative1.Cipher, "Both implementations should produce same output with same nonce")
}
