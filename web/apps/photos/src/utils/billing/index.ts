import {
    getTotalFamilyUsage,
    isPartOfFamily,
} from "@/new/photos/services/user";
import { Subscription } from "services/billingService";
import { BonusData, UserDetails } from "types/user";

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
