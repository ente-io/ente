import { CONFIRM_ACTION } from 'components/ConfirmDialog';
import constants from 'utils/strings/constants';
import billingService, {
    FREE_PLAN,
    PAYMENT_INTENT_STATUS,
    Plan,
    Subscription,
} from 'services/billingService';
import { SUBSCRIPTION_VERIFICATION_ERROR } from './common/errorUtil';
import { getData, LS_KEYS } from './storage/localStorage';

export function convertBytesToGBs(bytes, precision?): string {
    return (bytes / (1024 * 1024 * 1024)).toFixed(precision ?? 2);
}
export function hasPaidPlan(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return (
        subscription &&
        isSubscriptionActive(subscription) &&
        subscription.productID !== FREE_PLAN
    );
}

export function isSubscribed(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return hasPaidPlan(subscription) && !isSubscriptionCancelled(subscription);
}
export function isSubscriptionActive(subscription?: Subscription): boolean {
    subscription = subscription ?? getUserSubscription();
    return subscription && subscription.expiryTime > Date.now() * 1000;
}

export function isOnFreePlan(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return (
        subscription &&
        isSubscriptionActive(subscription) &&
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
        isSubscriptionActive(subscription) &&
        plan.id === subscription.productID &&
        !isSubscriptionCancelled(subscription)
    );
}

export async function buySubscription(
    plan: Plan,
    setDialogMessage,
    setLoading,
    setConfirmAction,
    closePlanSelectorModal
) {
    try {
        const subscription = getUserSubscription();
        setLoading(true);
        if (hasPaidPlan(subscription)) {
            await billingService.updateSubscription(plan.stripeID);
            if (isSubscriptionCancelled(subscription)) {
                await billingService.activateSubscription();
            }
            setLoading(false);
            await new Promise((resolve) =>
                setTimeout(() => resolve(null), 400)
            );
        } else {
            await billingService.buySubscription(plan.stripeID);
        }
        setDialogMessage({
            title: constants.SUBSCRIPTION_UPDATE_SUCCESS,
            close: { variant: 'success' },
        });
    } catch (err) {
        switch (err?.message) {
            case PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD:
                setConfirmAction(CONFIRM_ACTION.UPDATE_PAYMENT_METHOD);
                break;
            case SUBSCRIPTION_VERIFICATION_ERROR:
                setDialogMessage({
                    title: constants.SUBSCRIPTION_VERIFICATION_FAILED,
                    close: { variant: 'danger' },
                });
                break;
            default:
                setDialogMessage({
                    title: constants.SUBSCRIPTION_PURCHASE_FAILED,
                    close: { variant: 'danger' },
                });
        }
    } finally {
        setLoading(false);
        closePlanSelectorModal();
    }
}

export async function cancelSubscription(
    setDialogMessage,
    closePlanSelectorModal,
    setConfirmAction
) {
    try {
        await billingService.cancelSubscription();
        setDialogMessage({
            title: constants.SUBSCRIPTION_CANCEL_SUCCESS,
            close: { variant: 'success' },
        });
    } catch (e) {
        setDialogMessage({
            title: constants.SUBSCRIPTION_CANCEL_FAILED,
            close: { variant: 'danger' },
        });
    }
    closePlanSelectorModal();
    setConfirmAction(null);
}
