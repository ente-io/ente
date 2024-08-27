import log from "@/base/log";
import { openURL } from "@/new/photos/utils/web";
import { SetDialogBoxAttributes } from "@ente/shared/components/DialogBox/types";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { REDIRECTS, getRedirectURL } from "constants/redirects";
import { t } from "i18next";
import type { NextRouter } from "next/router";
import billingService from "services/billingService";
import { Plan, Subscription } from "types/billing";
import { SetLoading } from "types/gallery";
import { BonusData, UserDetails } from "types/user";
import { getSubscriptionPurchaseSuccessMessage } from "utils/ui";
import { getTotalFamilyUsage, isPartOfFamily } from "utils/user/family";

const PAYMENT_PROVIDER_STRIPE = "stripe";
const FREE_PLAN = "free";
const THIRTY_DAYS_IN_MICROSECONDS = 30 * 24 * 60 * 60 * 1000 * 1000;

enum FAILURE_REASON {
    AUTHENTICATION_FAILED = "authentication_failed",
    REQUIRE_PAYMENT_METHOD = "requires_payment_method",
    STRIPE_ERROR = "stripe_error",
    CANCELED = "canceled",
    SERVER_ERROR = "server_error",
}

enum RESPONSE_STATUS {
    success = "success",
    fail = "fail",
}

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

export async function updateSubscription(
    plan: Plan,
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading,
    closePlanSelectorModal: () => null,
) {
    try {
        setLoading(true);
        await billingService.updateSubscription(plan.stripeID);
    } catch (err) {
        setDialogMessage({
            title: t("ERROR"),
            content: t("SUBSCRIPTION_UPDATE_FAILED"),
            close: { variant: "critical" },
        });
    } finally {
        setLoading(false);
        closePlanSelectorModal();
    }
}

export async function cancelSubscription(
    setDialogMessage: SetDialogBoxAttributes,
    closePlanSelectorModal: () => void,
    setLoading: SetLoading,
) {
    try {
        setLoading(true);
        await billingService.cancelSubscription();
        setDialogMessage({
            title: t("SUCCESS"),
            content: t("SUBSCRIPTION_CANCEL_SUCCESS"),
            close: { variant: "accent" },
        });
    } catch (e) {
        setDialogMessage({
            title: t("ERROR"),
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
            title: t("SUCCESS"),
            content: t("SUBSCRIPTION_ACTIVATE_SUCCESS"),
            close: { variant: "accent" },
        });
    } catch (e) {
        setDialogMessage({
            title: t("ERROR"),
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
        await billingService.redirectToCustomerPortal();
    } catch (error) {
        setLoading(false);
        setDialogMessage({
            title: t("ERROR"),
            content: t("UNKNOWN_ERROR"),
            close: { variant: "critical" },
        });
    }
}

export async function manageFamilyMethod(
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading,
) {
    try {
        setLoading(true);
        const familyPortalRedirectURL = getRedirectURL(REDIRECTS.FAMILIES);
        openURL(familyPortalRedirectURL);
    } catch (e) {
        log.error("failed to redirect to family portal", e);
        setDialogMessage({
            title: t("ERROR"),
            content: t("UNKNOWN_ERROR"),
            close: { variant: "critical" },
        });
    } finally {
        setLoading(false);
    }
}

export async function checkSubscriptionPurchase(
    setDialogMessage: SetDialogBoxAttributes,
    router: NextRouter,
    setLoading: SetLoading,
) {
    const { session_id: sessionId, status, reason } = router.query ?? {};
    try {
        if (status === RESPONSE_STATUS.fail) {
            handleFailureReason(reason as string, setDialogMessage, setLoading);
        } else if (status === RESPONSE_STATUS.success) {
            try {
                const subscription = await billingService.verifySubscription(
                    sessionId as string,
                );
                setDialogMessage(
                    getSubscriptionPurchaseSuccessMessage(subscription),
                );
            } catch (e) {
                setDialogMessage({
                    title: t("ERROR"),
                    content: t("SUBSCRIPTION_VERIFICATION_ERROR"),
                    close: {},
                });
            }
        }
    } catch (e) {
        // ignore
    }
}

function handleFailureReason(
    reason: string,
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading,
): void {
    log.error(`subscription purchase failed: ${reason}`);
    switch (reason) {
        case FAILURE_REASON.CANCELED:
            setDialogMessage({
                title: t("MESSAGE"),
                content: t("SUBSCRIPTION_PURCHASE_CANCELLED"),
                close: { variant: "critical" },
            });
            break;
        case FAILURE_REASON.REQUIRE_PAYMENT_METHOD:
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

        case FAILURE_REASON.AUTHENTICATION_FAILED:
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
                title: t("ERROR"),
                content: t("SUBSCRIPTION_PURCHASE_FAILED"),
                close: { variant: "critical" },
            });
    }
}

export function planForSubscription(subscription: Subscription): Plan {
    return {
        id: subscription.productID,
        storage: subscription.storage,
        price: subscription.price,
        period: subscription.period,
        stripeID: subscription.productID,
        iosID: subscription.productID,
        androidID: subscription.productID,
    };
}
