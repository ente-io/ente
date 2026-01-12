package storagebonus

// Tracking represents entity used to track various referral history
type Tracking struct {
	// UserID of the user who invited the other person
	Invitor int64
	// UserID of the user who's invited by invitor
	Invitee int64
	// CreatedAt time when the user applied the code
	CreatedAt int64

	PlanType PlanType
}

type UserReferralPlanStat struct {
	PlanType      PlanType `json:"planType"`
	TotalCount    int      `json:"totalCount"`
	UpgradedCount int      `json:"upgradedCount"`
}

type UpdateReferralCodeRequest struct {
	Code string `json:"code" binding:"required"`
}

// PlanInfo represents the referral plan metadata
type PlanInfo struct {
	// IsEnabled indicates if the referral plan is enabled for given user
	IsEnabled bool `json:"isEnabled"`
	// Referral plan type
	PlanType PlanType `json:"planType"`
	// Storage which can be gained on successfully referral
	StorageInGB int64 `json:"storageInGB"`
	// Max storage which can be claimed by the user
	MaxClaimableStorageInGB int64 `json:"maxClaimableStorageInGB"`
}

type GetStorageBonusDetailResponse struct {
	ReferralStats   []UserReferralPlanStat `json:"referralStats"`
	Bonuses         []StorageBonus         `json:"bonuses"`
	RefCount        int                    `json:"refCount"`
	RefUpgradeCount int                    `json:"refUpgradeCount"`
	// Indicates if the user applied code during signup
	HasAppliedCode bool `json:"hasAppliedCode"`
}

// GetUserReferralView represents the basic view of the user's referral plan
// This is used to show the user's referral details in the UI
type GetUserReferralView struct {
	PlanInfo PlanInfo `json:"planInfo"`
	Code     *string  `json:"code"`
	// Indicates if the user can apply the referral code.
	EnableApplyCode bool `json:"enableApplyCode"`
	HasAppliedCode  bool `json:"hasAppliedCode"`
	// Indicates claimed referral storage
	ClaimedStorage int64 `json:"claimedStorage"`
	// Indicates if the user is part of a family and is the admin
	IsFamilyMember bool `json:"isFamilyMember"`
	// Number of times the user has changed their referral code
	CodeChangeAttempts int `json:"codeChangeAttempts"`
	// Remaining number of times the user can change their referral code
	RemainingCodeChangeAttempts int `json:"remainingCodeChangeAttempts"`
}
