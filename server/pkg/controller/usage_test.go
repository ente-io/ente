package controller

import "testing"

func TestGetLockerLimitsForTier(t *testing.T) {
	freeLimits := GetLockerLimitsForTier(false)
	if freeLimits.IsPaid {
		t.Fatal("expected free locker limits to report unpaid tier")
	}
	if freeLimits.FileLimit != lockerFreeFileLimit {
		t.Fatalf("unexpected free locker file limit: %d", freeLimits.FileLimit)
	}
	if freeLimits.StorageLimit != lockerFreeStorageLimit {
		t.Fatalf("unexpected free locker storage limit: %d", freeLimits.StorageLimit)
	}

	paidLimits := GetLockerLimitsForTier(true)
	if !paidLimits.IsPaid {
		t.Fatal("expected paid locker limits to report paid tier")
	}
	if paidLimits.FileLimit != lockerPaidFileLimit {
		t.Fatalf("unexpected paid locker file limit: %d", paidLimits.FileLimit)
	}
	if paidLimits.StorageLimit != lockerPaidStorageLimit {
		t.Fatalf("unexpected paid locker storage limit: %d", paidLimits.StorageLimit)
	}
}
