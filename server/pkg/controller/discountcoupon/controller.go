package discountcoupon

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/controller/email"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/discountcoupon"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"strings"
)

const MaxSendCount = 10

// AllowedProviders is a set of valid provider names for discount coupons.
// While adding new providers, consider adding customized templates in email package.
var AllowedProviders = map[string]bool{
	"Kagi": true,
	"Test": true,
}

type Controller struct {
	Repo                  *discountcoupon.Repository
	UserRepo              *repo.UserRepository
	BillingController     *controller.BillingController
	EmailNotificationCtrl *email.EmailNotificationController
	DiscordController     *discord.DiscordController
}

type ClaimCouponRequest struct {
	ProviderName string `json:"providerName" binding:"required"`
	Email        string `json:"email" binding:"required"`
}

type AddCouponsRequest struct {
	ProviderName string   `json:"providerName" binding:"required"`
	Codes        []string `json:"codes" binding:"required"`
}

func (c *Controller) ClaimCoupon(ctx *gin.Context, req ClaimCouponRequest) {
	go c.processClaimRequest(ctx, req)
}

func (c *Controller) processClaimRequest(ctx *gin.Context, req ClaimCouponRequest) {
	logger :=
		log.WithField("provider", req.ProviderName).
			WithField("email", req.Email).
			WithField("req_id", requestid.Get(ctx))

	if !AllowedProviders[req.ProviderName] {
		logger.Info("Invalid provider name for discount coupon")
		return
	}
	userID, err := c.UserRepo.GetUserIDWithEmail(req.Email)
	if err != nil {
		logger.WithError(err).Info("User not found for discount coupon claim")
		return
	}

	logger = logger.WithField("userID", userID)

	user, err := c.UserRepo.GetUserByIDInternal(userID)
	if err != nil {
		logger.WithError(err).Error("Failed to get user details")
		return
	}

	eligible, err := c.isUserEligible(user)
	if err != nil {
		logger.WithError(err).Error("Failed to check user eligibility")
		return
	}

	if !eligible {
		logger.Info("User not eligible for discount coupon")
		return
	}

	existingCoupon, err := c.Repo.GetClaimedCoupon(ctx, req.ProviderName, user.ID)
	if err != nil {
		logger.WithError(err).Error("Failed to get existing claimed coupon")
		return
	}

	if existingCoupon != nil {
		if existingCoupon.SentCount >= MaxSendCount {
			logger.Info("User has reached maximum send count for coupon")
			return
		}

		err = c.sendCouponEmail(ctx, user, existingCoupon.Code, req.ProviderName)
		if err != nil {
			logger.WithError(err).Error("Failed to resend coupon email")
			return
		}

		err = c.Repo.IncrementSentCount(ctx, req.ProviderName, existingCoupon.Code)
		if err != nil {
			logger.WithError(err).Error("Failed to increment sent count")
		}
		return
	}

	unclaimedCoupon, err := c.Repo.GetUnclaimedCoupon(ctx, req.ProviderName)
	if err != nil {
		logger.WithError(err).Error("Failed to get unclaimed coupon")
		return
	}

	if unclaimedCoupon == nil {
		c.alertCouponsDepletedDiscord(req.ProviderName)
		logger.Warn("No unclaimed coupons available")
		return
	}

	err = c.Repo.ClaimCoupon(ctx, req.ProviderName, unclaimedCoupon.Code, user.ID)
	if err != nil {
		logger.WithError(err).Error("Failed to claim coupon")
		return
	}

	err = c.sendCouponEmail(ctx, user, unclaimedCoupon.Code, req.ProviderName)
	if err != nil {
		logger.WithError(err).Error("Failed to send coupon email")
		return
	}

	logger.Info("Successfully claimed and sent coupon")
}

func (c *Controller) isUserEligible(user ente.User) (bool, error) {
	userID := user.ID
	if user.FamilyAdminID != nil && *user.FamilyAdminID != userID {
		return false, nil
	}

	err := c.BillingController.HasActiveSelfOrFamilySubscription(userID, true)
	if err != nil {
		return false, stacktrace.Propagate(err, "failed to check active subscription")
	}

	return true, nil
}

func (c *Controller) sendCouponEmail(ctx context.Context, user ente.User, couponCode, providerName string) error {
	templateData := map[string]interface{}{
		"CouponCode":   couponCode,
		"ProviderName": providerName,
	}

	var subject, templateName string
	switch providerName {
	case "Kagi":
		subject = "Ente Friends - Kagi trial code"
		templateName = "discount_coupon_kagi.html"
	case "Test":
		subject = "Ente Friends - Test trial code"
		templateName = "discount_coupon_test.html"
	default:
		subject = fmt.Sprintf("Your %s Discount Code", providerName)
		templateName = "discount_coupon.html"
	}
	return emailUtil.SendTemplatedEmailV2([]string{user.Email}, "Ente", "team@ente.io", subject, "base.html", templateName, templateData, nil)
}

func (c *Controller) alertCouponsDepletedDiscord(providerName string) {
	message := fmt.Sprintf("🚨 Alert: All discount coupons for provider **%s** have been claimed!", providerName)
	c.DiscordController.NotifyAdminAction(message)
}

func (c *Controller) AddCoupons(ctx *gin.Context, req AddCouponsRequest) error {
	if !AllowedProviders[req.ProviderName] {
		return ente.NewBadRequestWithMessage("Invalid provider name")
	}
	if len(req.Codes) == 0 {
		return ente.NewBadRequestWithMessage("No coupon codes provided")
	}

	// Filter out empty codes and validate
	validCodes := make([]string, 0, len(req.Codes))
	for _, code := range req.Codes {
		trimmed := strings.TrimSpace(code)
		if trimmed != "" {
			validCodes = append(validCodes, trimmed)
		}
	}
	if len(validCodes) == 0 {
		return nil
	}
	err := c.Repo.AddCoupons(ctx, req.ProviderName, req.Codes)
	if err != nil {
		return stacktrace.Propagate(err, "failed to add coupons")
	}

	return nil
}
