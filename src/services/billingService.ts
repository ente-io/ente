import { getEndpoint } from 'utils/common/apiUtil';
import { getStripePublishableKey, getToken } from 'utils/common/key';
import { checkConnectivity, runningInBrowser } from 'utils/common/';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { convertToHumanReadable } from 'utils/billingUtil';
import { loadStripe, Stripe } from '@stripe/stripe-js';
import { SUBSCRIPTION_VERIFICATION_ERROR } from 'utils/common/errorUtil';
import HTTPService from './HTTPService';
import { logError } from 'utils/sentry';

const ENDPOINT = getEndpoint();

export enum PAYMENT_INTENT_STATUS {
    SUCCESS = 'success',
    REQUIRE_ACTION = 'requires_action',
    REQUIRE_PAYMENT_METHOD = 'requires_payment_method',
}
export interface Subscription {
    id: number;
    userID: number;
    productID: string;
    storage: number;
    originalTransactionID: string;
    expiryTime: number;
    paymentProvider: string;
    attributes: {
        isCancelled: boolean;
    };
    price:string;
    period:string;
}
export interface Plan {
    id: string;
    androidID: string;
    iosID: string;
    storage: number;
    price: string;
    period: string;
    stripeID: string;
}

export interface SubscriptionUpdateResponse {
    subscription: Subscription;
    status: PAYMENT_INTENT_STATUS;
    clientSecret: string;
}
export const FREE_PLAN = 'free';
class billingService {
    private stripe: Stripe;

    constructor() {
        try {
            const publishableKey = getStripePublishableKey();
            const main = async () => {
                try {
                    this.stripe = await loadStripe(publishableKey);
                } catch (e) {
                    logError(e);
                }
            };
            runningInBrowser() && checkConnectivity() && main();
        } catch (e) {
            logError(e);
        }
    }

    public async updatePlans() {
        try {
            const response = await HTTPService.get(`${ENDPOINT}/billing/plans/v2`);
            const { plans } = response.data;
            setData(LS_KEYS.PLANS, plans);
        } catch (e) {
            logError(e, 'failed to get plans');
        }
    }

    public async syncSubscription() {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/subscription`,
                null,
                {
                    'X-Auth-Token': getToken(),
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            logError(e, 'failed to get user\'s subscription details');
        }
    }

    public async buyPaidSubscription(productID) {
        try {
            const response = await this.createCheckoutSession(productID);
            await this.stripe.redirectToCheckout({
                sessionId: response.data.sessionID,
            });
        } catch (e) {
            logError(e, 'unable to buy subscription');
            throw e;
        }
    }

    public async updateSubscription(productID) {
        try {
            const response = await HTTPService.post(
                `${ENDPOINT}/billing/stripe/update-subscription`,
                {
                    productID,
                },
                null,
                {
                    'X-Auth-Token': getToken(),
                },
            );
            const { result } = response.data;
            switch (result.status) {
                case PAYMENT_INTENT_STATUS.SUCCESS:
                    // subscription updated successfully
                    // no-op required
                    break;
                case PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD:
                    throw new Error(
                        PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD,
                    );
                case PAYMENT_INTENT_STATUS.REQUIRE_ACTION:
                    {
                        const { error } = await this.stripe.confirmCardPayment(
                            result.clientSecret,
                        );
                        if (error) {
                            throw error;
                        }
                    }
                    break;
            }
        } catch (e) {
            logError(e);
            throw e;
        }
        try {
            await this.verifySubscription();
        } catch (e) {
            throw new Error(SUBSCRIPTION_VERIFICATION_ERROR);
        }
    }

    public async cancelSubscription() {
        try {
            const response = await HTTPService.post(
                `${ENDPOINT}/billing/stripe/cancel-subscription`,
                null,
                null,
                {
                    'X-Auth-Token': getToken(),
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            logError(e);
            throw e;
        }
    }

    public async activateSubscription() {
        try {
            const response = await HTTPService.post(
                `${ENDPOINT}/billing/stripe/activate-subscription`,
                null,
                null,
                {
                    'X-Auth-Token': getToken(),
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            logError(e);
            throw e;
        }
    }

    private async createCheckoutSession(productID) {
        return HTTPService.get(
            `${ENDPOINT}/billing/stripe/checkout-session`,
            {
                productID,
            },
            {
                'X-Auth-Token': getToken(),
            },
        );
    }

    public async verifySubscription(
        sessionID: string = null,
    ): Promise<Subscription> {
        try {
            const response = await HTTPService.post(
                `${ENDPOINT}/billing/verify-subscription`,
                {
                    paymentProvider: 'stripe',
                    productID: null,
                    VerificationData: sessionID,
                },
                null,
                {
                    'X-Auth-Token': getToken(),
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
            return subscription;
        } catch (err) {
            logError(err, 'Error while verifying subscription');
            throw err;
        }
    }

    public async redirectToCustomerPortal() {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/stripe/customer-portal`,
                null,
                {
                    'X-Auth-Token': getToken(),
                },
            );
            window.location.href = response.data.url;
        } catch (e) {
            logError(e, 'unable to get customer portal url');
            throw e;
        }
    }

    public async getUsage() {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/usage`,
                { startTime: 0, endTime: Date.now() * 1000 },
                {
                    'X-Auth-Token': getToken(),
                },
            );
            return convertToHumanReadable(response.data.usage);
        } catch (e) {
            logError(e, 'error getting usage');
        }
    }
}

export default new billingService();
