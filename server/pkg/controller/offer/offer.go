package offer

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"os"

	"github.com/ente-io/museum/pkg/controller/usercache"

	"github.com/ente-io/museum/ente"
	storeageBonusEntity "github.com/ente-io/museum/ente/storagebonus"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/storagebonus"
	"github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/museum/pkg/utils/billing"
	"github.com/ente-io/museum/pkg/utils/config"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
)

// OfferController controls all offer related operations
type OfferController struct {
	BlackFridayOffers ente.BlackFridayOfferPerCountry
	UserRepo          repo.UserRepository
	DiscordController *discord.DiscordController
	StorageBonusRepo  *storagebonus.Repository
	UserCacheCtrl     *usercache.Controller
}

func NewOfferController(
	userRepo repo.UserRepository,
	discordController *discord.DiscordController,
	storageBonusRepo *storagebonus.Repository,
	userCacheCtrl *usercache.Controller,
) *OfferController {
	blackFridayOffers := make(ente.BlackFridayOfferPerCountry)
	path, err := config.BillingConfigFilePath("black-friday.json")
	if err != nil {
		log.Fatalf("Error getting offer config file: %v", err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		log.Error("Error reading config file", err)
	}
	err = json.Unmarshal(data, &blackFridayOffers)
	if err != nil {
		log.Error("Error un-marshalling JSON", err)
	}
	return &OfferController{
		BlackFridayOffers: blackFridayOffers,
		UserRepo:          userRepo,
		DiscordController: discordController,
		StorageBonusRepo:  storageBonusRepo,
		UserCacheCtrl:     userCacheCtrl,
	}
}

func (c *OfferController) GetBlackFridayOffers(countryCode string) []ente.BlackFridayOffer {
	if array.StringInList(countryCode, billing.CountriesInEU) {
		countryCode = "EU"
	}

	if offers, found := c.BlackFridayOffers[countryCode]; found {
		return offers
	}
	// unable to find plans for given country code, return plans for default country
	defaultCountry := billing.GetDefaultPlanCountry()
	return c.BlackFridayOffers[defaultCountry]
}

func (c *OfferController) ApplyOffer(email string, productID string) error {
	var offerToBeApplied ente.BlackFridayOffer
	found := false
	for _, offers := range c.BlackFridayOffers {
		for _, offer := range offers {
			if offer.ID == productID {
				found = true
				offerToBeApplied = offer
			}
		}
	}
	if !found {
		return stacktrace.Propagate(ente.ErrNotFound, "Could not find an offer for  "+productID)
	}
	var validTill int64
	if offerToBeApplied.Period == ente.Period3Years {
		validTill = time.NDaysFromNow(3 * 365)
	} else if offerToBeApplied.Period == ente.Period5Years {
		validTill = time.NDaysFromNow(5 * 365)
	} else {
		return stacktrace.Propagate(ente.ErrNotFound, "Could not find a valid time period for  "+productID)
	}

	userID, err := c.UserRepo.GetUserIDWithEmail(email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			log.Error("Product purchased with unknown email: " + email)
			c.DiscordController.Notify("Unknown user paid " + offerToBeApplied.Price)
			return nil
		} else {
			return stacktrace.Propagate(err, "")
		}
	}

	err = c.StorageBonusRepo.InsertAddOnBonus(context.Background(), storeageBonusEntity.AddOnBf2023, userID, validTill, offerToBeApplied.Storage)
	if err != nil {
		c.DiscordController.Notify("Error inserting bonus")
		return stacktrace.Propagate(err, "")
	}
	go c.UserCacheCtrl.GetActiveStorageBonus(context.Background(), userID)
	c.DiscordController.NotifyBlackFridayUser(userID, offerToBeApplied.Price)
	return nil
}
