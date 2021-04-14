import { FREE_PLAN, Plan, Subscription } from 'services/billingService';
import { getData, LS_KEYS } from './storage/localStorage';

export function convertBytesToGBs(bytes, precision?): string {
    return (bytes / (1024 * 1024 * 1024)).toFixed(precision ?? 2);
}
export function hasPaidPlan(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return (
        subscription &&
        isPlanActive(subscription) &&
        subscription.productID !== FREE_PLAN
    );
}

export function isSubscribed(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return hasPaidPlan(subscription) && !isSubscriptionCancelled(subscription);
}
export function isPlanActive(subscription?: Subscription): boolean {
    subscription = subscription ?? getUserSubscription();
    return subscription && subscription.expiryTime > Date.now() * 1000;
}

export function isOnFreePlan(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return (
        subscription &&
        isPlanActive(subscription) &&
        subscription.productID === FREE_PLAN
    );
}

export function isSubscriptionCancelled(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return subscription && subscription.isCancelled;
}

export function getUserSubscription(): Subscription {
    return getData(LS_KEYS.SUBSCRIPTION);
}

export function getPlans(): Plan[] {
    return getData(LS_KEYS.PLANS);
}
export function isUserRenewingPlan(plan: Plan, subscription: Subscription) {
    return (
        plan.id === subscription.productID &&
        !isSubscriptionCancelled(subscription)
    );
}
