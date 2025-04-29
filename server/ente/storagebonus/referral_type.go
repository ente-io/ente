package storagebonus

import (
	"fmt"
)

type PlanType string

const (
	// TenGbOnUpgrade plan when both the parties get 10 GB surplus storage.
	// The invitee gets 10 GB storage on successful signup
	// The invitor gets 10 GB storage only after the invitee upgrades to a paid plan
	TenGbOnUpgrade PlanType = "10_GB_ON_UPGRADE"
)

// SignUpInviteeBonus returns the storage which can be gained by the invitee on successful signup with a referral code
func (c PlanType) SignUpInviteeBonus() int64 {
	switch c {
	case TenGbOnUpgrade:
		return 10 * 1024 * 1024 * 1024
	default:
		panic(fmt.Sprintf("SignUpInviteeBonus value not configured for %s", c))
	}
}

// SignUpInvitorBonus returns the storage which can be gained by the invitor when some sign ups using their code
func (c PlanType) SignUpInvitorBonus() int64 {
	switch c {
	case TenGbOnUpgrade:
		return 0
	default:
		// panic if the plan type is not supported
		panic("unsupported plan type")
	}
}

// InvitorBonusOnInviteeUpgrade returns the storage which can be gained by the invitor when the invitee upgrades to a paid plan
func (c PlanType) InvitorBonusOnInviteeUpgrade() int64 {
	switch c {
	case TenGbOnUpgrade:
		return 10 * 1024 * 1024 * 1024
	default:
		// panic if the plan type is not supported
		panic("unsupported plan type")
	}
}
