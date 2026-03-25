package ente

import "testing"

func TestSupportUpdateBonusValidate_AllowsNonProfitBonus(t *testing.T) {
	req := SupportUpdateBonus{
		BonusType:   "ADD_ON_NON_PROFIT",
		Action:      ADD,
		UserID:      1,
		Year:        3,
		StorageInGB: 200,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("expected non-profit bonus to be valid, got error: %v", err)
	}
}

func TestSupportUpdateBonusValidate_RejectsInvalidNonProfitBonus(t *testing.T) {
	req := SupportUpdateBonus{
		BonusType:   "ADD_ON_NON_PROFIT",
		Action:      ADD,
		UserID:      1,
		Year:        101,
		StorageInGB: 200,
	}

	if err := req.Validate(); err == nil {
		t.Fatal("expected invalid non-profit bonus to be rejected")
	}
}
