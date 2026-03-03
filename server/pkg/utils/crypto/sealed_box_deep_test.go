package crypto

import (
	"crypto/rand"
	"encoding/base64"
	"testing"

	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/blake2b"
	"golang.org/x/crypto/nacl/box"
)

func deriveSealedBoxNonce(ephemeralPublicKey *[BoxPublicKeyBytes]byte, recipientPublicKey *[BoxPublicKeyBytes]byte) ([SecretBoxNonceBytes]byte, error) {
	nonceInput := make([]byte, BoxPublicKeyBytes*2)
	copy(nonceInput[:BoxPublicKeyBytes], ephemeralPublicKey[:])
	copy(nonceInput[BoxPublicKeyBytes:], recipientPublicKey[:])

	hash, err := blake2b.New(SecretBoxNonceBytes, nil)
	if err != nil {
		return [SecretBoxNonceBytes]byte{}, err
	}
	hash.Write(nonceInput)

	var nonce [SecretBoxNonceBytes]byte
	copy(nonce[:], hash.Sum(nil))
	return nonce, nil
}

func TestNonceDerivationInDetail(t *testing.T) {
	recipientPublicKey, _, err := box.GenerateKey(rand.Reader)
	require.NoError(t, err)

	ephemeralPublicKey, _, err := box.GenerateKey(rand.Reader)
	require.NoError(t, err)

	t.Run("unkeyed_blake2b_derivation_is_deterministic", func(t *testing.T) {
		nonce1, err := deriveSealedBoxNonce(ephemeralPublicKey, recipientPublicKey)
		require.NoError(t, err)

		nonce2, err := deriveSealedBoxNonce(ephemeralPublicKey, recipientPublicKey)
		require.NoError(t, err)

		require.Equal(t, nonce1, nonce2, "nonce derivation must be deterministic for same inputs")
	})

	t.Run("keyed_blake2b_derivation_is_different", func(t *testing.T) {
		expectedNonce, err := deriveSealedBoxNonce(ephemeralPublicKey, recipientPublicKey)
		require.NoError(t, err)

		keyedHash, err := blake2b.New(SecretBoxNonceBytes, ephemeralPublicKey[:])
		require.NoError(t, err)
		keyedHash.Write(recipientPublicKey[:])

		keyedNonce := keyedHash.Sum(nil)
		require.NotEqual(t, expectedNonce[:], keyedNonce, "keyed derivation must not match sealed-box nonce")
	})
}

func TestNativeSealedBoxRoundTrip(t *testing.T) {
	recipientPublicKey, recipientPrivateKey, err := box.GenerateKey(rand.Reader)
	require.NoError(t, err)

	message := []byte("test message for sealed box")
	token := base64.URLEncoding.EncodeToString(message)
	publicKey := base64.StdEncoding.EncodeToString(recipientPublicKey[:])

	encrypted, err := GetEncryptedTokenNative(token, publicKey)
	require.NoError(t, err)

	encryptedBytes, err := base64.StdEncoding.DecodeString(encrypted)
	require.NoError(t, err)

	decrypted, err := openSealedBox(encryptedBytes, recipientPublicKey, recipientPrivateKey)
	require.NoError(t, err)
	require.Equal(t, message, decrypted, "decrypted message should match original")
}
