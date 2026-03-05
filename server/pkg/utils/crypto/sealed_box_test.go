package crypto

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"testing"

	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/blake2b"
	"golang.org/x/crypto/nacl/box"
)

func openSealedBox(sealed []byte, recipientPublicKey *[BoxPublicKeyBytes]byte, recipientPrivateKey *[BoxPublicKeyBytes]byte) ([]byte, error) {
	if len(sealed) < BoxPublicKeyBytes+16 {
		return nil, errors.New("invalid sealed box length")
	}

	var ephemeralPublicKey [BoxPublicKeyBytes]byte
	copy(ephemeralPublicKey[:], sealed[:BoxPublicKeyBytes])

	nonceInput := make([]byte, BoxPublicKeyBytes*2)
	copy(nonceInput[:BoxPublicKeyBytes], ephemeralPublicKey[:])
	copy(nonceInput[BoxPublicKeyBytes:], recipientPublicKey[:])

	hash, err := blake2b.New(SecretBoxNonceBytes, nil)
	if err != nil {
		return nil, err
	}
	hash.Write(nonceInput)

	var nonce [SecretBoxNonceBytes]byte
	copy(nonce[:], hash.Sum(nil))

	decrypted, ok := box.Open(nil, sealed[BoxPublicKeyBytes:], &nonce, &ephemeralPublicKey, recipientPrivateKey)
	if !ok {
		return nil, errors.New("failed to open sealed box")
	}
	return decrypted, nil
}

func TestSealedBoxCompatibility(t *testing.T) {
	recipientPublicKey, recipientPrivateKey, err := box.GenerateKey(rand.Reader)
	require.NoError(t, err, "should generate keypair")

	tokenBytes := []byte("test-token-12345")
	publicKeyBase64 := base64.StdEncoding.EncodeToString(recipientPublicKey[:])
	tokenBase64 := base64.URLEncoding.EncodeToString(tokenBytes)

	tests := []struct {
		name      string
		encryptFn func(token, publicKey string) (string, error)
	}{
		{
			name:      "compat_wrapper",
			encryptFn: GetEncryptedToken,
		},
		{
			name:      "native",
			encryptFn: GetEncryptedTokenNative,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			encrypted, err := tc.encryptFn(tokenBase64, publicKeyBase64)
			require.NoError(t, err, "sealed-box encryption should succeed")

			encryptedBytes, err := base64.StdEncoding.DecodeString(encrypted)
			require.NoError(t, err)

			expectedLen := BoxPublicKeyBytes + 16 + len(tokenBytes)
			require.Equal(t, expectedLen, len(encryptedBytes), "sealed box should have correct length")

			decrypted, err := openSealedBox(encryptedBytes, recipientPublicKey, recipientPrivateKey)
			require.NoError(t, err, "sealed box should decrypt with recipient keypair")
			require.Equal(t, tokenBytes, decrypted, "decrypted bytes should match original")
		})
	}
}
