package commonbilling

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/storagebonus"
	"github.com/ente-io/stacktrace"
)

type Controller struct {
	StorageBonusRepo *storagebonus.Repository
	UserRepo         *repo.UserRepository
	UsageRepo        *repo.UsageRepository
}

func NewController(
	storageBonusRepo *storagebonus.Repository,
	userRepo *repo.UserRepository,
	usageRepo *repo.UsageRepository,
) *Controller {
	return &Controller{
		StorageBonusRepo: storageBonusRepo,
		UserRepo:         userRepo,
		UsageRepo:        usageRepo,
	}
}

func (c *Controller) CanDowngradeToGivenStorage(newStorage int64, userID int64) (bool, error) {
	adminID, err := c.UserRepo.GetFamilyAdminID(userID)
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}

	if adminID == nil {
		bonusStorage, bonErr := c.StorageBonusRepo.GetPaidAddonSurplusStorage(context.Background(), userID)
		if bonErr != nil {
			return false, stacktrace.Propagate(err, "")
		}
		usage, err := c.UsageRepo.GetUsage(userID)
		if err != nil {
			return false, stacktrace.Propagate(err, "")
		}
		if usage > (newStorage + *bonusStorage) {
			return false, stacktrace.Propagate(err, fmt.Sprintf("user with %d usage can not downgrade to %d", usage, newStorage))
		}
	} else {
		bonusStorage, bonErr := c.StorageBonusRepo.GetPaidAddonSurplusStorage(context.Background(), *adminID)
		if bonErr != nil {
			return false, stacktrace.Propagate(err, "")
		}
		usage, err := c.UsageRepo.StorageForFamilyAdmin(*adminID)
		if err != nil {
			return false, stacktrace.Propagate(err, "")
		}
		if usage > (newStorage + *bonusStorage) {
			return false, stacktrace.Propagate(err, fmt.Sprintf("familyUser with %d usage can not downgrade to %d", usage, newStorage))
		}
	}
	return true, nil
}
