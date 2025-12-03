package crypto

import (
	"crypto/rand"
	"encoding/base64"
	"testing"

	"github.com/GoKillers/libsodium-go/cryptobox"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/nacl/box"
)

func TestSealedBoxCompatibility(t *testing.T) {
	// Initialize libsodium
	InitSodiumForTest()

	// Generate a test keypair for the recipient
	recipientPublicKey, recipientPrivateKey, err := box.GenerateKey(rand.Reader)
	require.NoError(t, err, "should generate keypair")

	// Prepare test data
	originalToken := "test-token-12345"
	tokenBytes := []byte(originalToken)
	publicKeyBase64 := base64.StdEncoding.EncodeToString(recipientPublicKey[:])
	tokenBase64 := base64.URLEncoding.EncodeToString(tokenBytes)

	t.Run("libsodium sealed box can be opened", func(t *testing.T) {
		// Encrypt with libsodium's crypto_box_seal
		encryptedLibsodium, errCode := cryptobox.CryptoBoxSeal(tokenBytes, recipientPublicKey[:])
		require.Equal(t, 0, errCode, "libsodium encryption should succeed")

		// Try to open with libsodium's crypto_box_seal_open
		decrypted, errCode := cryptobox.CryptoBoxSealOpen(encryptedLibsodium, recipientPublicKey[:], recipientPrivateKey[:])
		require.Equal(t, 0, errCode, "libsodium should decrypt its own sealed box")
		require.Equal(t, tokenBytes, decrypted, "decrypted should match original")
	})

	t.Run("compare GetEncryptedToken with GetEncryptedTokenNative", func(t *testing.T) {
		// Encrypt with both implementations
		encryptedLibsodium, err := GetEncryptedToken(tokenBase64, publicKeyBase64)
		require.NoError(t, err, "libsodium GetEncryptedToken should succeed")

		encryptedNative, err := GetEncryptedTokenNative(tokenBase64, publicKeyBase64)
		require.NoError(t, err, "native GetEncryptedTokenNative should succeed")

		// Decode the encrypted data
		encryptedLibsodiumBytes, err := base64.StdEncoding.DecodeString(encryptedLibsodium)
		require.NoError(t, err)

		encryptedNativeBytes, err := base64.StdEncoding.DecodeString(encryptedNative)
		require.NoError(t, err)

		// Both should be 48 bytes + len(tokenBytes) (32 bytes ephemeral pubkey + 16 bytes auth tag + message)
		expectedLen := 32 + 16 + len(tokenBytes)
		require.Equal(t, expectedLen, len(encryptedLibsodiumBytes), "libsodium sealed box should have correct length")
		require.Equal(t, expectedLen, len(encryptedNativeBytes), "native sealed box should have correct length")

		// Try to decrypt libsodium's output with libsodium
		decryptedLib, errCode := cryptobox.CryptoBoxSealOpen(encryptedLibsodiumBytes, recipientPublicKey[:], recipientPrivateKey[:])
		require.Equal(t, 0, errCode, "libsodium should decrypt its own output")
		require.Equal(t, tokenBytes, decryptedLib, "libsodium decrypted should match original")

		// CRITICAL TEST: Try to decrypt native's output with libsodium
		decryptedNative, errCode := cryptobox.CryptoBoxSealOpen(encryptedNativeBytes, recipientPublicKey[:], recipientPrivateKey[:])
		if errCode != 0 {
			t.Errorf("COMPATIBILITY ISSUE: libsodium cannot decrypt native sealed box (error code: %d)", errCode)
			t.Log("This confirms the nonce derivation is incompatible")
		} else {
			require.Equal(t, tokenBytes, decryptedNative, "cross-decryption should work if compatible")
			t.Log("SUCCESS: Native implementation is compatible with libsodium")
		}
	})

}
