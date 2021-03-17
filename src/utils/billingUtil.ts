import { FREE_PLAN, Plan, Subscription } from 'services/subscriptionService';
import { getData, LS_KEYS } from './storage/localStorage';

export function convertBytesToGBs(bytes, precision?): string {
    return (bytes / (1024 * 1024 * 1024)).toFixed(precision ?? 2);
}
export function hasActivePaidPlan(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return (
        subscription &&
        planIsActive(subscription) &&
        subscription.productID !== FREE_PLAN
    );
}
export function planIsActive(subscription?: Subscription): boolean {
    subscription = subscription ?? getUserSubscription();
    return subscription && subscription.expiryTime > Date.now() * 1000;
}

export function hadSubscribedEarlier(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return subscription && subscription.productID !== FREE_PLAN;
}

export function getUserSubscription(): Subscription {
    return getData(LS_KEYS.SUBSCRIPTION);
}

export function getPlans(): Plan[] {
    return getData(LS_KEYS.PLANS);
}
