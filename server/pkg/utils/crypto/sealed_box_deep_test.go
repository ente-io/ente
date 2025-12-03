package crypto

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"testing"

	"github.com/GoKillers/libsodium-go/cryptobox"
	generichash "github.com/GoKillers/libsodium-go/cryptogenerichash"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/blake2b"
	"golang.org/x/crypto/nacl/box"
)

func TestNonceDerivationInDetail(t *testing.T) {
	// Initialize libsodium
	InitSodiumForTest()

	// Generate a test keypair
	recipientPublicKey, _, err := box.GenerateKey(rand.Reader)
	require.NoError(t, err)

	// Generate ephemeral keypair
	ephemeralPublicKey, _, err := box.GenerateKey(rand.Reader)
	require.NoError(t, err)

	t.Run("test_libsodium_nonce_derivation", func(t *testing.T) {
		// According to libsodium source, crypto_box_seal derives nonce as:
		// crypto_generichash(nonce, 24, ephemeral_pk || recipient_pk, 64, NULL, 0)
		// This is an UNKEYED hash of the concatenated public keys

		// Method 1: What our native code currently does (unkeyed hash)
		nonceInput := make([]byte, 64)
		copy(nonceInput[:32], ephemeralPublicKey[:])
		copy(nonceInput[32:], recipientPublicKey[:])

		hash1, err := blake2b.New(24, nil) // unkeyed
		require.NoError(t, err)
		hash1.Write(nonceInput)
		nonce1 := hash1.Sum(nil)

		// Method 2: What the comment suggests (keyed hash - INCORRECT)
		// crypto_generichash(nonce, 24, recipient_pk, 32, ephemeral_pk, 32)
		// This would be recipient_pk as message, ephemeral_pk as key
		hash2, err := blake2b.New(24, ephemeralPublicKey[:])
		require.NoError(t, err)
		hash2.Write(recipientPublicKey[:])
		nonce2 := hash2.Sum(nil)

		// Method 3: Using libsodium's generic hash to verify
		// This should match Method 1 if our understanding is correct
		nonce3, errCode := generichash.CryptoGenericHash(24, nonceInput, nil)
		require.Equal(t, 0, errCode)

		t.Logf("Method 1 (native - unkeyed): %s", hex.EncodeToString(nonce1))
		t.Logf("Method 2 (keyed - wrong):     %s", hex.EncodeToString(nonce2))
		t.Logf("Method 3 (libsodium):         %s", hex.EncodeToString(nonce3))

		// The correct implementation should match libsodium
		require.Equal(t, nonce3, nonce1, "Native implementation should match libsodium's nonce derivation")
		require.NotEqual(t, nonce2, nonce3, "Keyed hash should NOT match (proving the comment is incorrect)")
	})

	t.Run("actual_interop_test", func(t *testing.T) {
		// Let's do a real interop test with fixed keys to be absolutely sure
		// Generate a fixed recipient keypair for reproducible testing
		var fixedRecipientPubKey [32]byte
		var fixedRecipientPrivKey [32]byte
		for i := range fixedRecipientPubKey {
			fixedRecipientPubKey[i] = byte(i)
			fixedRecipientPrivKey[i] = byte(255 - i)
		}

		// Actually generate a valid keypair
		realPubKey, realPrivKey, err := box.GenerateKey(rand.Reader)
		require.NoError(t, err)

		message := []byte("test message for sealed box")

		// Encrypt with libsodium
		sealed, errCode := cryptobox.CryptoBoxSeal(message, realPubKey[:])
		require.Equal(t, 0, errCode, "libsodium seal should work")

		// Decrypt with libsodium to verify it works
		unsealed, errCode := cryptobox.CryptoBoxSealOpen(sealed, realPubKey[:], realPrivKey[:])
		require.Equal(t, 0, errCode, "libsodium unseal should work")
		require.Equal(t, message, unsealed, "round trip should work")

		// Now test with our functions
		token := base64.URLEncoding.EncodeToString(message)
		pubKeyB64 := base64.StdEncoding.EncodeToString(realPubKey[:])

		encrypted, err := GetEncryptedTokenNative(token, pubKeyB64)
		require.NoError(t, err)

		encryptedBytes, err := base64.StdEncoding.DecodeString(encrypted)
		require.NoError(t, err)

		// Try to decrypt with libsodium
		decrypted, errCode := cryptobox.CryptoBoxSealOpen(encryptedBytes, realPubKey[:], realPrivKey[:])
		if errCode != 0 {
			t.Errorf("FAILED: libsodium cannot decrypt native sealed box")
		} else {
			require.Equal(t, message, decrypted, "Decryption should produce original message")
			t.Log("SUCCESS: Native sealed box is compatible with libsodium")
		}
	})
}