import { t } from 'i18next';

import billingService from 'services/billingService';
import { Plan, Subscription } from 'types/billing';
import { NextRouter } from 'next/router';
import { SetLoading } from 'types/gallery';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import { logError } from '@ente/shared/sentry';
import { SetDialogBoxAttributes } from '@ente/shared/components/DialogBox/types';
import { openLink } from 'utils/common';
import { isPartOfFamily, getTotalFamilyUsage } from 'utils/user/family';
import { BonusData, UserDetails } from 'types/user';
import { getSubscriptionPurchaseSuccessMessage } from 'utils/ui';
import { getRedirectURL, REDIRECTS } from 'constants/redirects';

const PAYMENT_PROVIDER_STRIPE = 'stripe';
const PAYMENT_PROVIDER_APPSTORE = 'appstore';
const PAYMENT_PROVIDER_PLAYSTORE = 'playstore';
const FREE_PLAN = 'free';

enum FAILURE_REASON {
    AUTHENTICATION_FAILED = 'authentication_failed',
    REQUIRE_PAYMENT_METHOD = 'requires_payment_method',
    STRIPE_ERROR = 'stripe_error',
    CANCELED = 'canceled',
    SERVER_ERROR = 'server_error',
}

enum RESPONSE_STATUS {
    success = 'success',
    fail = 'fail',
}

const StorageUnits = ['B', 'KB', 'MB', 'GB', 'TB'];

const ONE_GB = 1024 * 1024 * 1024;

export function convertBytesToGBs(bytes: number, precision = 0): string {
    return (bytes / (1024 * 1024 * 1024)).toFixed(precision);
}

export function makeHumanReadableStorage(
    bytes: number,
    { roundUp } = { roundUp: false }
): string {
    if (bytes <= 0) {
        return `0 ${t('STORAGE_UNITS.MB')}`;
    }
    const i = Math.floor(Math.log(bytes) / Math.log(1024));

    let quantity = bytes / Math.pow(1024, i);
    let unit = StorageUnits[i];

    if (quantity > 100 && unit !== 'GB') {
        quantity /= 1024;
        unit = StorageUnits[i + 1];
    }

    quantity = Number(quantity.toFixed(1));

    if (bytes >= 10 * ONE_GB) {
        if (roundUp) {
            quantity = Math.ceil(quantity);
        } else {
            quantity = Math.round(quantity);
        }
    }

    return `${quantity} ${t(`STORAGE_UNITS.${unit}`)}`;
}

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
            bonus.type.startsWith('ADD_ON')
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

export function hasMobileSubscription(subscription: Subscription) {
    return (
        hasPaidSubscription(subscription) &&
        subscription.paymentProvider.length > 0 &&
        (subscription.paymentProvider === PAYMENT_PROVIDER_APPSTORE ||
            subscription.paymentProvider === PAYMENT_PROVIDER_PLAYSTORE)
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

export function isPopularPlan(plan: Plan) {
    return plan.storage === 100 * ONE_GB;
}

export async function updateSubscription(
    plan: Plan,
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading,
    closePlanSelectorModal: () => null
) {
    try {
        setLoading(true);
        await billingService.updateSubscription(plan.stripeID);
    } catch (err) {
        setDialogMessage({
            title: t('ERROR'),
            content: t('SUBSCRIPTION_UPDATE_FAILED'),
            close: { variant: 'critical' },
        });
    } finally {
        setLoading(false);
        closePlanSelectorModal();
    }
}

export async function cancelSubscription(
    setDialogMessage: SetDialogBoxAttributes,
    closePlanSelectorModal: () => void,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.cancelSubscription();
        setDialogMessage({
            title: t('SUCCESS'),
            content: t('SUBSCRIPTION_CANCEL_SUCCESS'),
            close: { variant: 'accent' },
        });
    } catch (e) {
        setDialogMessage({
            title: t('ERROR'),
            content: t('SUBSCRIPTION_CANCEL_FAILED'),
            close: { variant: 'critical' },
        });
    } finally {
        closePlanSelectorModal();
        setLoading(false);
    }
}

export async function activateSubscription(
    setDialogMessage: SetDialogBoxAttributes,
    closePlanSelectorModal: () => void,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.activateSubscription();
        setDialogMessage({
            title: t('SUCCESS'),
            content: t('SUBSCRIPTION_ACTIVATE_SUCCESS'),
            close: { variant: 'accent' },
        });
    } catch (e) {
        setDialogMessage({
            title: t('ERROR'),
            content: t('SUBSCRIPTION_ACTIVATE_FAILED'),
            close: { variant: 'critical' },
        });
    } finally {
        closePlanSelectorModal();
        setLoading(false);
    }
}

export async function updatePaymentMethod(
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.redirectToCustomerPortal();
    } catch (error) {
        setLoading(false);
        setDialogMessage({
            title: t('ERROR'),
            content: t('UNKNOWN_ERROR'),
            close: { variant: 'critical' },
        });
    }
}

export async function manageFamilyMethod(
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        const familyPortalRedirectURL = getRedirectURL(REDIRECTS.FAMILIES);
        openLink(familyPortalRedirectURL, true);
    } catch (error) {
        logError(error, 'failed to redirect to family portal');
        setDialogMessage({
            title: t('ERROR'),
            content: t('UNKNOWN_ERROR'),
            close: { variant: 'critical' },
        });
    } finally {
        setLoading(false);
    }
}

export async function checkSubscriptionPurchase(
    setDialogMessage: SetDialogBoxAttributes,
    router: NextRouter,
    setLoading: SetLoading
) {
    const { session_id: sessionId, status, reason } = router.query ?? {};
    try {
        if (status === RESPONSE_STATUS.fail) {
            handleFailureReason(reason as string, setDialogMessage, setLoading);
        } else if (status === RESPONSE_STATUS.success) {
            try {
                const subscription = await billingService.verifySubscription(
                    sessionId as string
                );
                setDialogMessage(
                    getSubscriptionPurchaseSuccessMessage(subscription)
                );
            } catch (e) {
                setDialogMessage({
                    title: t('ERROR'),
                    content: t('SUBSCRIPTION_VERIFICATION_ERROR'),
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
    setLoading: SetLoading
): void {
    logError(Error(reason), 'subscription purchase failed');
    switch (reason) {
        case FAILURE_REASON.CANCELED:
            setDialogMessage({
                title: t('MESSAGE'),
                content: t('SUBSCRIPTION_PURCHASE_CANCELLED'),
                close: { variant: 'critical' },
            });
            break;
        case FAILURE_REASON.REQUIRE_PAYMENT_METHOD:
            setDialogMessage({
                title: t('UPDATE_PAYMENT_METHOD'),
                content: t('UPDATE_PAYMENT_METHOD_MESSAGE'),

                proceed: {
                    text: t('UPDATE_PAYMENT_METHOD'),
                    variant: 'accent',
                    action: updatePaymentMethod.bind(
                        null,

                        setDialogMessage,
                        setLoading
                    ),
                },
                close: { text: t('CANCEL') },
            });
            break;

        case FAILURE_REASON.AUTHENTICATION_FAILED:
            setDialogMessage({
                title: t('UPDATE_PAYMENT_METHOD'),
                content: t('STRIPE_AUTHENTICATION_FAILED'),

                proceed: {
                    text: t('UPDATE_PAYMENT_METHOD'),
                    variant: 'accent',
                    action: updatePaymentMethod.bind(
                        null,

                        setDialogMessage,
                        setLoading
                    ),
                },
                close: { text: t('CANCEL') },
            });
            break;

        default:
            setDialogMessage({
                title: t('ERROR'),
                content: t('SUBSCRIPTION_PURCHASE_FAILED'),
                close: { variant: 'critical' },
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
