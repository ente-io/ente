import constants from 'utils/strings/constants';
import billingService, {
    FREE_PLAN,
    PAYMENT_INTENT_STATUS,
    Plan,
    Subscription,
} from 'services/billingService';
import { NextRouter } from 'next/router';
import { SetDialogMessage } from 'components/MessageDialog';
import { SetLoading } from 'pages/gallery';
import { getData, LS_KEYS } from './storage/localStorage';
import { CustomError } from './common/errorUtil';

const STRIPE = 'stripe';

export function convertBytesToGBs(bytes, precision?): string {
    return (bytes / (1024 * 1024 * 1024)).toFixed(precision ?? 2);
}

export function convertToHumanReadable(bytes: number, precision = 2): string {
    if (bytes === 0) {
        return '0 MB';
    }
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

    return (bytes / Math.pow(1024, i)).toFixed(precision) + ' ' + sizes[i];
}

export function hasPaidSubscription(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return (
        subscription &&
        isSubscriptionActive(subscription) &&
        subscription.productID !== FREE_PLAN
    );
}

export function isSubscribed(subscription?: Subscription) {
    subscription = subscription ?? getUserSubscription();
    return (
        hasPaidSubscription(subscription) &&
        !isSubscriptionCancelled(subscription)
    );
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
    return subscription && subscription.attributes.isCancelled;
}

export function getUserSubscription(): Subscription {
    return getData(LS_KEYS.SUBSCRIPTION);
}

export function getPlans(): Plan[] {
    return getData(LS_KEYS.PLANS);
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
        hasPaidSubscription(subscription) &&
        subscription.paymentProvider.length > 0 &&
        subscription.paymentProvider === STRIPE
    );
}

export async function updateSubscription(
    plan: Plan,
    setDialogMessage: SetDialogMessage,
    setLoading: SetLoading,
    closePlanSelectorModal: () => null
) {
    try {
        setLoading(true);
        await billingService.updateSubscription(plan.stripeID);
        setLoading(false);
        await new Promise((resolve) => setTimeout(() => resolve(null), 400));
        setDialogMessage({
            title: constants.SUCCESS,
            content: constants.SUBSCRIPTION_PURCHASE_SUCCESS(
                getUserSubscription().expiryTime
            ),
            close: { variant: 'success' },
        });
    } catch (err) {
        switch (err?.message) {
            case PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD:
                setDialogMessage({
                    title: constants.UPDATE_PAYMENT_METHOD,
                    content: constants.UPDATE_PAYMENT_METHOD_MESSAGE,
                    staticBackdrop: true,
                    proceed: {
                        text: constants.UPDATE_PAYMENT_METHOD,
                        variant: 'success',
                        action: updatePaymentMethod.bind(
                            null,

                            setDialogMessage,
                            setLoading
                        ),
                    },
                    close: { text: constants.CANCEL },
                });
                break;
            case CustomError.SUBSCRIPTION_VERIFICATION_ERROR:
                setDialogMessage({
                    title: constants.ERROR,
                    content: constants.SUBSCRIPTION_VERIFICATION_FAILED,
                    close: { variant: 'danger' },
                });
                break;
            default:
                setDialogMessage({
                    title: constants.ERROR,
                    content: constants.SUBSCRIPTION_PURCHASE_FAILED,
                    close: { variant: 'danger' },
                });
        }
    } finally {
        setLoading(false);
        closePlanSelectorModal();
    }
}

export async function cancelSubscription(
    setDialogMessage: SetDialogMessage,
    closePlanSelectorModal: () => null,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.cancelSubscription();
        setDialogMessage({
            title: constants.SUCCESS,
            content: constants.SUBSCRIPTION_CANCEL_SUCCESS,
            close: { variant: 'success' },
        });
    } catch (e) {
        setDialogMessage({
            title: constants.ERROR,
            content: constants.SUBSCRIPTION_CANCEL_FAILED,
            close: { variant: 'danger' },
        });
    } finally {
        closePlanSelectorModal();
        setLoading(false);
    }
}

export async function activateSubscription(
    setDialogMessage: SetDialogMessage,
    closePlanSelectorModal: () => null,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.activateSubscription();
        setDialogMessage({
            title: constants.SUCCESS,
            content: constants.SUBSCRIPTION_ACTIVATE_SUCCESS,
            close: { variant: 'success' },
        });
    } catch (e) {
        setDialogMessage({
            title: constants.ERROR,
            content: constants.SUBSCRIPTION_ACTIVATE_FAILED,
            close: { variant: 'danger' },
        });
    } finally {
        closePlanSelectorModal();
        setLoading(false);
    }
}

export async function updatePaymentMethod(
    setDialogMessage: SetDialogMessage,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.redirectToCustomerPortal();
    } catch (error) {
        setDialogMessage({
            title: constants.ERROR,
            content: constants.UNKNOWN_ERROR,
            close: { variant: 'danger' },
        });
    } finally {
        setLoading(true);
    }
}

export async function checkSubscriptionPurchase(
    setDialogMessage: SetDialogMessage,
    router: NextRouter
) {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const sessionId = urlParams.get('session_id');
        if (sessionId === '-1') {
            setDialogMessage({
                title: constants.MESSAGE,
                content: constants.SUBSCRIPTION_PURCHASE_CANCELLED,
                close: { variant: 'danger' },
            });
        } else if (sessionId) {
            try {
                const subscription = await billingService.verifySubscription(
                    sessionId
                );
                setDialogMessage({
                    title: constants.SUBSCRIPTION_PURCHASE_SUCCESS_TITLE,
                    close: { variant: 'success' },
                    content: constants.SUBSCRIPTION_PURCHASE_SUCCESS(
                        subscription?.expiryTime
                    ),
                });
            } catch (e) {
                setDialogMessage({
                    title: constants.ERROR,
                    content: CustomError.SUBSCRIPTION_VERIFICATION_ERROR,
                    close: {},
                });
            }
        }
    } catch (e) {
        // ignore
    } finally {
        router.push('gallery', undefined, { shallow: true });
    }
}

export function planForSubscription(subscription: Subscription) {
    if (!subscription) {
        return null;
    }
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
