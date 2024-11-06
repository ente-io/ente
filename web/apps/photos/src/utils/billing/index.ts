import log from "@/base/log";
import {
    getTotalFamilyUsage,
    isPartOfFamily,
} from "@/new/photos/services/user";
import { SetDialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";
import { t } from "i18next";
import type { NextRouter } from "next/router";
import billingService, {
    Plan,
    redirectToCustomerPortal,
    Subscription,
} from "services/billingService";
import { SetLoading } from "types/gallery";
import { BonusData, UserDetails } from "types/user";
import { getSubscriptionPurchaseSuccessMessage } from "utils/ui";

const PAYMENT_PROVIDER_STRIPE = "stripe";
const FREE_PLAN = "free";
const THIRTY_DAYS_IN_MICROSECONDS = 30 * 24 * 60 * 60 * 1000 * 1000;

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

    // Using stripe
    if (subscription.paymentProvider == "stripe") {
        // Update their existing subscription to the new plan.
        return "updateSubscriptionToPlan";
    }

    // Using one of the mobile app stores
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

export function hasPaidSubscription(subscription: Subscription) {
    return (
        subscription &&
        isSubscriptionActive(subscription) &&
        subscription.productID !== FREE_PLAN
    );
}

export function isSubscribed(subscription: Subscription) {
    return (
        hasPaidSubscription(subscription) &&
        !isSubscriptionCancelled(subscription)
    );
}
export function isSubscriptionActive(subscription: Subscription): boolean {
    return subscription && subscription.expiryTime > Date.now() * 1000;
}

export function isOnFreePlan(subscription: Subscription) {
    return (
        subscription &&
        isSubscriptionActive(subscription) &&
        subscription.productID === FREE_PLAN
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

export function isSubscriptionCancelled(subscription: Subscription) {
    return subscription && subscription.attributes.isCancelled;
}

export function getLocalUserSubscription(): Subscription {
    return getData(LS_KEYS.SUBSCRIPTION);
}

export function isUserSubscribedPlan(plan: Plan, subscription: Subscription) {
    return (
        isSubscriptionActive(subscription) &&
        (plan.stripeID === subscription.productID ||
            plan.iosID === subscription.productID ||
            plan.androidID === subscription.productID)
    );
}
export function hasStripeSubscription(subscription: Subscription) {
    return (
        subscription.paymentProvider.length > 0 &&
        subscription.paymentProvider === PAYMENT_PROVIDER_STRIPE
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

export function isSubscriptionPastDue(subscription: Subscription) {
    const currentTime = Date.now() * 1000;
    return (
        !isSubscriptionCancelled(subscription) &&
        subscription.expiryTime < currentTime &&
        subscription.expiryTime >= currentTime - THIRTY_DAYS_IN_MICROSECONDS
    );
}

export const isPopularPlan = (plan: Plan) =>
    plan.storage === 100 * 1024 * 1024 * 1024; /* 100 GB */

export async function cancelSubscription(
    setDialogMessage: SetDialogBoxAttributes,
    closePlanSelectorModal: () => void,
    setLoading: SetLoading,
) {
    try {
        setLoading(true);
        await billingService.cancelSubscription();
        setDialogMessage({
            title: t("success"),
            content: t("SUBSCRIPTION_CANCEL_SUCCESS"),
            close: { variant: "accent" },
        });
    } catch (e) {
        setDialogMessage({
            title: t("error"),
            content: t("SUBSCRIPTION_CANCEL_FAILED"),
            close: { variant: "critical" },
        });
    } finally {
        closePlanSelectorModal();
        setLoading(false);
    }
}

export async function activateSubscription(
    setDialogMessage: SetDialogBoxAttributes,
    closePlanSelectorModal: () => void,
    setLoading: SetLoading,
) {
    try {
        setLoading(true);
        await billingService.activateSubscription();
        setDialogMessage({
            title: t("success"),
            content: t("SUBSCRIPTION_ACTIVATE_SUCCESS"),
            close: { variant: "accent" },
        });
    } catch (e) {
        setDialogMessage({
            title: t("error"),
            content: t("SUBSCRIPTION_ACTIVATE_FAILED"),
            close: { variant: "critical" },
        });
    } finally {
        closePlanSelectorModal();
        setLoading(false);
    }
}

export async function updatePaymentMethod(
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading,
) {
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

    if (status === "success") {
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
                        action: updatePaymentMethod.bind(
                            null,

                            setDialogMessage,
                            setLoading,
                        ),
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
                        action: updatePaymentMethod.bind(
                            null,

                            setDialogMessage,
                            setLoading,
                        ),
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
