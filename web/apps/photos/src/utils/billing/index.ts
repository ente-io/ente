import log from "@/base/log";
import {
    getTotalFamilyUsage,
    isPartOfFamily,
} from "@/new/photos/services/user";
import { SetDialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import { t } from "i18next";
import type { NextRouter } from "next/router";
import billingService, {
    redirectToCustomerPortal,
    Subscription,
} from "services/billingService";
import { SetLoading } from "types/gallery";
import { BonusData, UserDetails } from "types/user";
import { getSubscriptionPurchaseSuccessMessage } from "utils/ui";

export type PlanSelectionOutcome =
    | "buyPlan"
    | "updateSubscriptionToPlan"
    | "cancelOnMobile"
    | "contactSupport";

/**
 * Return the outcome that should happen when the user selects a paid plan on
 * the plan selection screen.
 *
 * @param subscription Their current subscription details.
 */
export const planSelectionOutcome = (
    subscription: Subscription | undefined,
) => {
    // This shouldn't happen, but we need this case to handle missing types.
    if (!subscription) return "buyPlan";

    // The user is a on a free plan and can buy the plan they selected.
    if (subscription.productID == "free") return "buyPlan";

    // Their existing subscription has expired. They can buy a new plan.
    if (subscription.expiryTime < Date.now() * 1000) return "buyPlan";

    // -- The user already has an active subscription to a paid plan.

    // Using Stripe.
    if (subscription.paymentProvider == "stripe") {
        // Update their existing subscription to the new plan.
        return "updateSubscriptionToPlan";
    }

    // Using one of the mobile app stores.
    if (
        subscription.paymentProvider == "appstore" ||
        subscription.paymentProvider == "playstore"
    ) {
        // They need to cancel first on the mobile app stores.
        return "cancelOnMobile";
    }

    // Some other bespoke case. They should contact support.
    return "contactSupport";
};

/**
 * Return true if the given {@link Subscription} has not expired.
 */
export const isSubscriptionActive = (subscription: Subscription) =>
    subscription && subscription.expiryTime > Date.now() * 1000;

/**
 * Return true if the given active {@link Subscription} is for a paid plan.
 */
export const isSubscriptionActivePaid = (subscription: Subscription) =>
    subscription &&
    isSubscriptionActive(subscription) &&
    subscription.productID != "free";

/**
 * Return true if the given active {@link Subscription} is for a free plan.
 */
export const isSubscriptionActiveFree = (subscription: Subscription) =>
    subscription &&
    isSubscriptionActive(subscription) &&
    subscription.productID == "free";

/**
 * Return true if the given {@link Subscription} is using Stripe.
 */
export const isSubscriptionStripe = (subscription: Subscription) =>
    subscription && subscription.paymentProvider == "stripe";

/**
 * Return true if the given {@link Subscription} has the cancelled attribute.
 */
export const isSubscriptionCancelled = (subscription: Subscription) =>
    subscription && subscription.attributes.isCancelled;

export function isSubscriptionPastDue(subscription: Subscription) {
    const thirtyDaysMicroseconds = 30 * 24 * 60 * 60 * 1000 * 1000;
    const currentTime = Date.now() * 1000;
    return (
        !isSubscriptionCancelled(subscription) &&
        subscription.expiryTime < currentTime &&
        subscription.expiryTime >= currentTime - thirtyDaysMicroseconds
    );
}

// Checks if the bonus data contain any bonus whose type starts with 'ADD_ON'
export function hasAddOnBonus(bonusData?: BonusData) {
    return (
        bonusData &&
        bonusData.storageBonuses &&
        bonusData.storageBonuses.length > 0 &&
        bonusData.storageBonuses.some((bonus) =>
            bonus.type.startsWith("ADD_ON"),
        )
    );
}

export function hasExceededStorageQuota(userDetails: UserDetails) {
    const bonusStorage = userDetails.storageBonus ?? 0;
    if (isPartOfFamily(userDetails.familyData)) {
        const usage = getTotalFamilyUsage(userDetails.familyData);
        return usage > userDetails.familyData.storage + bonusStorage;
    } else {
        return (
            userDetails.usage > userDetails.subscription.storage + bonusStorage
        );
    }
}

/**
 * When the payments app redirects back to us after a plan purchase or update
 * completes, it sets various query parameters to relay the status of the action
 * back to us.
 *
 * Check if these query parameters exist, and if so, act on them appropriately.
 */
export async function checkSubscriptionPurchase(
    setDialogMessage: SetDialogBoxAttributes,
    router: NextRouter,
    setLoading: SetLoading,
) {
    const { session_id: sessionId, status, reason } = router.query ?? {};

    if (status == "success") {
        try {
            const subscription = await billingService.verifySubscription(
                sessionId as string,
            );
            setDialogMessage(
                getSubscriptionPurchaseSuccessMessage(subscription),
            );
        } catch (e) {
            setDialogMessage({
                title: t("error"),
                content: t("SUBSCRIPTION_VERIFICATION_ERROR"),
                close: {},
            });
        }
    } else if (status == "fail") {
        log.error(`subscription purchase failed: ${reason}`);
        switch (reason) {
            case "canceled":
                setDialogMessage({
                    content: t("SUBSCRIPTION_PURCHASE_CANCELLED"),
                    close: { variant: "critical" },
                });
                break;
            case "requires_payment_method":
                setDialogMessage({
                    title: t("UPDATE_PAYMENT_METHOD"),
                    content: t("UPDATE_PAYMENT_METHOD_MESSAGE"),

                    proceed: {
                        text: t("UPDATE_PAYMENT_METHOD"),
                        variant: "accent",
                        action: async () => {
                            try {
                                setLoading(true);
                                await redirectToCustomerPortal();
                            } catch (error) {
                                setLoading(false);
                                setDialogMessage({
                                    title: t("error"),
                                    content: t("generic_error_retry"),
                                    close: { variant: "critical" },
                                });
                            }
                        },
                    },
                    close: { text: t("cancel") },
                });
                break;

            case "authentication_failed":
                setDialogMessage({
                    title: t("UPDATE_PAYMENT_METHOD"),
                    content: t("STRIPE_AUTHENTICATION_FAILED"),

                    proceed: {
                        text: t("UPDATE_PAYMENT_METHOD"),
                        variant: "accent",
                        action: async () => {
                            try {
                                setLoading(true);
                                await redirectToCustomerPortal();
                            } catch (error) {
                                setLoading(false);
                                setDialogMessage({
                                    title: t("error"),
                                    content: t("generic_error_retry"),
                                    close: { variant: "critical" },
                                });
                            }
                        },
                    },
                    close: { text: t("cancel") },
                });
                break;

            default:
                setDialogMessage({
                    title: t("error"),
                    content: t("SUBSCRIPTION_PURCHASE_FAILED"),
                    close: { variant: "critical" },
                });
        }
    }
}
