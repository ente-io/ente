package random

import (
	"fmt"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
)

func GenerateSixDigitOtp() (string, error) {
	n, err := auth.GenerateRandomInt(1_000_000)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	return fmt.Sprintf("%06d", n), nil
}
