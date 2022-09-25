import constants from 'utils/strings/constants';
import billingService from 'services/billingService';
import { Plan, Subscription } from 'types/billing';
import { NextRouter } from 'next/router';
import { SetLoading } from 'types/gallery';
import { getData, LS_KEYS } from '../storage/localStorage';
import { CustomError } from '../error';
import { logError } from '../sentry';
import { SetDialogBoxAttributes } from 'types/dialogBox';
import { getFamilyPortalRedirectURL } from 'services/userService';
import { FamilyData, FamilyMember, User, UserDetails } from 'types/user';
import { openLink } from 'utils/common';

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
    round: 'round-up' | 'round-down' = 'round-down'
): string {
    if (bytes === 0) {
        return '0 MB';
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
        if (round === 'round-up') {
            quantity = Math.round(quantity + 1);
        } else {
            quantity = Math.round(quantity);
        }
    }

    return `${quantity} ${unit}`;
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

export function isSubscriptionCancelled(subscription: Subscription) {
    return subscription && subscription.attributes.isCancelled;
}

// isPartOfFamily return true if the current user is part of some family plan
export function isPartOfFamily(familyData: FamilyData): boolean {
    return Boolean(
        familyData && familyData.members && familyData.members.length > 0
    );
}

// hasNonAdminFamilyMembers return true if the admin user has members in his family
export function hasNonAdminFamilyMembers(familyData: FamilyData): boolean {
    return Boolean(isPartOfFamily(familyData) && familyData.members.length > 1);
}

export function isFamilyAdmin(familyData: FamilyData): boolean {
    const familyAdmin: FamilyMember = getFamilyPlanAdmin(familyData);
    const user: User = getData(LS_KEYS.USER);
    return familyAdmin.email === user.email;
}

export function getFamilyPlanAdmin(familyData: FamilyData): FamilyMember {
    if (isPartOfFamily(familyData)) {
        return familyData.members.find((x) => x.isAdmin);
    } else {
        logError(
            Error(
                'verify user is part of family plan before calling this method'
            ),
            'invalid getFamilyPlanAdmin call'
        );
    }
}

export function getTotalFamilyUsage(familyData: FamilyData): number {
    return familyData.members.reduce(
        (sum, currentMember) => sum + currentMember.usage,
        0
    );
}

export function getLocalUserSubscription(): Subscription {
    return getData(LS_KEYS.SUBSCRIPTION);
}

export function getLocalFamilyData(): FamilyData {
    return getData(LS_KEYS.FAMILY_DATA);
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
    if (isPartOfFamily(userDetails.familyData)) {
        const usage = getTotalFamilyUsage(userDetails.familyData);
        return usage > userDetails.familyData.storage;
    } else {
        return userDetails.usage > userDetails.subscription.storage;
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
            title: constants.ERROR,
            content: constants.SUBSCRIPTION_UPDATE_FAILED,
            close: { variant: 'danger' },
        });
    } finally {
        setLoading(false);
        closePlanSelectorModal();
    }
}

export async function cancelSubscription(
    setDialogMessage: SetDialogBoxAttributes,
    closePlanSelectorModal: () => null,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.cancelSubscription();
        setDialogMessage({
            title: constants.SUCCESS,
            content: constants.SUBSCRIPTION_CANCEL_SUCCESS,
            close: { variant: 'accent' },
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
    setDialogMessage: SetDialogBoxAttributes,
    closePlanSelectorModal: () => null,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.activateSubscription();
        setDialogMessage({
            title: constants.SUCCESS,
            content: constants.SUBSCRIPTION_ACTIVATE_SUCCESS,
            close: { variant: 'accent' },
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
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        await billingService.redirectToCustomerPortal();
    } catch (error) {
        setLoading(false);
        setDialogMessage({
            title: constants.ERROR,
            content: constants.UNKNOWN_ERROR,
            close: { variant: 'danger' },
        });
    }
}

export async function manageFamilyMethod(
    setDialogMessage: SetDialogBoxAttributes,
    setLoading: SetLoading
) {
    try {
        setLoading(true);
        const url = await getFamilyPortalRedirectURL();
        openLink(url, true);
    } catch (error) {
        logError(error, 'failed to redirect to family portal');
        setDialogMessage({
            title: constants.ERROR,
            content: constants.UNKNOWN_ERROR,
            close: { variant: 'danger' },
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
                setDialogMessage({
                    title: constants.SUBSCRIPTION_PURCHASE_SUCCESS_TITLE,
                    close: { variant: 'accent' },
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
                title: constants.MESSAGE,
                content: constants.SUBSCRIPTION_PURCHASE_CANCELLED,
                close: { variant: 'danger' },
            });
            break;
        case FAILURE_REASON.REQUIRE_PAYMENT_METHOD:
            setDialogMessage({
                title: constants.UPDATE_PAYMENT_METHOD,
                content: constants.UPDATE_PAYMENT_METHOD_MESSAGE,

                proceed: {
                    text: constants.UPDATE_PAYMENT_METHOD,
                    variant: 'accent',
                    action: updatePaymentMethod.bind(
                        null,

                        setDialogMessage,
                        setLoading
                    ),
                },
                close: { text: constants.CANCEL },
            });
            break;

        case FAILURE_REASON.AUTHENTICATION_FAILED:
            setDialogMessage({
                title: constants.UPDATE_PAYMENT_METHOD,
                content: constants.STRIPE_AUTHENTICATION_FAILED,

                proceed: {
                    text: constants.UPDATE_PAYMENT_METHOD,
                    variant: 'accent',
                    action: updatePaymentMethod.bind(
                        null,

                        setDialogMessage,
                        setLoading
                    ),
                },
                close: { text: constants.CANCEL },
            });
            break;

        default:
            setDialogMessage({
                title: constants.ERROR,
                content: constants.SUBSCRIPTION_PURCHASE_FAILED,
                close: { variant: 'danger' },
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
