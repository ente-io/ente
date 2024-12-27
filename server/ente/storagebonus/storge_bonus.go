package storagebonus

type BonusType string

const (
	// Referral bonus is gained by inviting others
	Referral BonusType = "REFERRAL"
	// SignUp for applying code shared by others during sign up
	// Note: In the future, for surplus types which should be only applied once, we can add unique constraints
	SignUp BonusType = "SIGN_UP"

	// AddOnSupport is the bonus for users added by the support team
	AddOnSupport = "ADD_ON_SUPPORT"
	// AddOnBf is the bonus for users who have opted for the Black Friday offers
	AddOnBf2023 = "ADD_ON_BF_2023"
	AddOnBf2024 = "ADD_ON_BF_2024"
	// In the future, we can add various types of bonuses based on different events like Anniversary,
	// or finishing tasks like ML indexing, enabling sharing etc etc
)

// PaidAddOnTypes : These add-ons can be purchased by the users and help in the expiry of an account
// as long as the add-on is active.
var PaidAddOnTypes = []BonusType{AddOnSupport, AddOnBf2023, AddOnBf2024}

// ExtendsExpiry returns true if the bonus type extends the expiry of the account.
// By default, all bonuses don't extend expiry.
func (t BonusType) ExtendsExpiry() bool {
	switch t {
	case AddOnSupport, AddOnBf2023, AddOnBf2024:
		return true
	case Referral, SignUp:
		return false
	default:
		return false
	}
}

func BonusFromType(bonusType string) BonusType {
	switch bonusType {
	case "REFERRAL":
		return Referral
	case "SIGN_UP":
		return SignUp
	case "ADD_ON_SUPPORT":
		return AddOnSupport
	case "ADD_ON_BF_2023":
		return AddOnBf2023
	case "ADD_ON_BF_2024":
		return AddOnBf2024
	default:
		return ""
	}
}

// RestrictToDoublingStorage returns true if the bonus type restricts the doubling of storage.
// This indicates, the usable bonus storage should not exceed the current plan storage.
// Note: Current plan storage includes both base subscription and storage bonus that can ExtendsExpiry
func (t BonusType) RestrictToDoublingStorage() bool {
	switch t {
	case Referral, SignUp:
		return true
	case AddOnSupport, AddOnBf2023, AddOnBf2024:
		return false
	default:
		return true
	}
}

type RevokeReason string

const (
	Fraud RevokeReason = "FRAUD"
	// Expired is usually used to take away one time bonus.
	Expired RevokeReason = "EXPIRED"
	// Discontinued Used when storagebonus is taken away before other user deleted their account
	// or stopped subscription or user decides to pause subscription after anniversary gift
	Discontinued RevokeReason = "DISCONTINUED"
)

type StorageBonus struct {
	UserID int64 `json:"-"`
	// Amount of storage bonus added to the account
	Storage   int64     `json:"storage"`
	Type      BonusType `json:"type"`
	CreatedAt int64     `json:"createdAt"`
	UpdatedAt int64     `json:"-"`
	// ValidTill represents the validity of the storage bonus. If it is 0, it is valid forever.
	ValidTill    int64         `json:"validTill"`
	RevokeReason *RevokeReason `json:"-"`
	IsRevoked    bool          `json:"isRevoked"`
}

type ActiveStorageBonus struct {
	StorageBonuses []StorageBonus `json:"storageBonuses"`
}

func (a *ActiveStorageBonus) GetMaxExpiry() int64 {
	if a == nil {
		return 0
	}
	maxExpiry := int64(0)
	for _, bonus := range a.StorageBonuses {
		if bonus.Type.ExtendsExpiry() && bonus.ValidTill > maxExpiry {
			maxExpiry = bonus.ValidTill
		}
	}
	return maxExpiry
}

func (a *ActiveStorageBonus) GetReferralBonus() int64 {
	if a == nil {
		return 0
	}
	referralBonus := int64(0)
	for _, bonus := range a.StorageBonuses {
		if bonus.Type.RestrictToDoublingStorage() {
			referralBonus += bonus.Storage
		}
	}
	return referralBonus
}

func (a *ActiveStorageBonus) GetAddonStorage() int64 {
	if a == nil {
		return 0
	}
	addonStorage := int64(0)
	for _, bonus := range a.StorageBonuses {
		if !bonus.Type.RestrictToDoublingStorage() {
			addonStorage += bonus.Storage
		}
	}
	return addonStorage
}

// GetUsableBonus Returns the add_on_bonus + referral_bonus for a given user. The referral bonus is restricted
// to max of addonStorage + subStorage
func (a *ActiveStorageBonus) GetUsableBonus(subStorage int64) int64 {
	refBonus := a.GetReferralBonus()
	totalSubAndAddOnStorage := a.GetAddonStorage() + subStorage
	if refBonus > totalSubAndAddOnStorage {
		refBonus = totalSubAndAddOnStorage
	}
	return a.GetAddonStorage() + refBonus
}

type GetBonusResult struct {
	StorageBonuses []StorageBonus
}
