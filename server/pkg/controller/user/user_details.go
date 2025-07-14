package user

import (
	"errors"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/ente/details"
	bonus "github.com/ente-io/museum/ente/storagebonus"
	"github.com/ente-io/museum/pkg/utils/billing"
	"github.com/ente-io/museum/pkg/utils/recover"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"golang.org/x/sync/errgroup"
)

func (c *UserController) GetUser(userID int64) (ente.User, error) {
	user, err := c.UserRepo.Get(userID)
	if err != nil && errors.Is(err, ente.ErrUserDeleted) {
		return ente.User{}, stacktrace.Propagate(ente.ErrUserNotFound, "")
	}
	return user, err

}
func (c *UserController) GetDetailsV2(ctx *gin.Context, userID int64, fetchMemoryCount bool, app ente.App) (details.UserDetailsResponse, error) {

	g := new(errgroup.Group)
	var user *ente.User
	var familyData *ente.FamilyMemberResponse
	var subscription *ente.Subscription
	var canDisableEmailMFA bool
	var passkeyCount int64
	var fileCount, sharedCollectionCount, usage int64
	var bonus *bonus.ActiveStorageBonus
	g.Go(func() error {
		resp, err := c.GetUser(userID)
		if err != nil {
			return stacktrace.Propagate(err, "failed to get user")
		}
		user = &resp
		bonusUserId := userID
		if user.FamilyAdminID != nil {
			bonusUserId = *user.FamilyAdminID
			familyDataResp, familyErr := c.FamilyController.FetchMembersForAdminID(ctx, *user.FamilyAdminID)
			if familyErr != nil {
				return stacktrace.Propagate(familyErr, "")
			}
			familyData = &familyDataResp
		}
		bonusValue, bonusErr := c.UserCacheController.GetActiveStorageBonus(ctx, bonusUserId)
		if bonusErr != nil {
			return stacktrace.Propagate(bonusErr, "failed to fetch storage bonus")
		}
		bonus = bonusValue
		return nil
	})

	g.Go(func() error {
		subResp, err := c.BillingController.GetSubscription(ctx, userID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		subscription = &subResp
		return nil
	})
	g.Go(func() error {
		isSRPSetupDone, err := c.UserAuthRepo.IsSRPSetupDone(ctx, userID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		canDisableEmailMFA = isSRPSetupDone
		return nil
	})

	g.Go(func() error {
		return recover.Int64ToInt64RecoverWrapper(userID, c.FileRepo.GetUsage, &usage)
	})
	g.Go(func() error {
		cnt, err := c.PasskeyRepo.GetPasskeyCount(userID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		passkeyCount = cnt
		return nil
	})

	if fetchMemoryCount {
		g.Go(func() error {
			fCount, err := c.UserCacheController.GetUserFileCountWithCache(userID, app)
			if err == nil {
				fileCount = fCount
			}

			return err
		})
	}

	// g.Wait waits for all goroutines to complete
	// and returns the first non-nil error returned
	// by one of the goroutines.
	if err := g.Wait(); err != nil {
		return details.UserDetailsResponse{}, stacktrace.Propagate(err, "")
	}
	var planStoreForBonusComputation = subscription.Storage
	expiryBuffer := int64(0)
	if value, ok := billing.ProviderToExpiryGracePeriodMap[subscription.PaymentProvider]; ok {
		expiryBuffer = value
	}
	if (subscription.ExpiryTime + expiryBuffer) < time.Microseconds() {
		planStoreForBonusComputation = 0
	}
	if familyData != nil {
		if (familyData.ExpiryTime + expiryBuffer) < time.Microseconds() {
			familyData.Storage = 0
		} else {
			planStoreForBonusComputation = familyData.Storage
		}
	}
	storageBonus := bonus.GetUsableBonus(planStoreForBonusComputation)
	var result = details.UserDetailsResponse{
		Email:        user.Email,
		FamilyData:   familyData,
		Subscription: *subscription,
		Usage:        usage,
		StorageBonus: storageBonus,
		ProfileData: &ente.ProfileData{
			CanDisableEmailMFA: canDisableEmailMFA,
			IsEmailMFAEnabled:  *user.IsEmailMFAEnabled,
			IsTwoFactorEnabled: *user.IsTwoFactorEnabled,
			PasskeyCount:       passkeyCount,
		},
		BonusData: bonus,
	}
	if fetchMemoryCount {
		result.FileCount = &fileCount
		// Note: SharedCollectionsCount is deprecated. Returning default value as 0
		result.SharedCollectionsCount = &sharedCollectionCount
	}
	return result, nil
}
