package rollout

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
)

// IsInPercentageRollout deterministically decides whether a user belongs to a rollout bucket.
// nonce should remain constant for a given experiment so the same users stay opted-in.
func IsInPercentageRollout(userID int64, nonce string, percentage int) bool {
	switch {
	case percentage <= 0:
		return false
	case percentage >= 100:
		return true
	}

	payload := fmt.Sprintf("%d:%s", userID, nonce)
	hash := sha256.Sum256([]byte(payload))
	value := binary.BigEndian.Uint64(hash[:8])

	return int(value%100) < percentage
}
