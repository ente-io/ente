import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
const ENDPOINT = getEndpoint();
import { getStripePublishableKey, getToken } from 'utils/common/key';
import { checkConnectivity, runningInBrowser } from 'utils/common/';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { convertBytesToGBs } from 'utils/billingUtil';
import { loadStripe, Stripe } from '@stripe/stripe-js';
import { SUBSCRIPTION_VERIFICATION_ERROR } from 'utils/common/errorUtil';

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
            let publishableKey = getStripePublishableKey();
            const main = async () => {
                this.stripe = await loadStripe(publishableKey);
            };
            runningInBrowser() && checkConnectivity() && main();
        } catch (e) {
            console.warn(e);
        }
    }
    public async updatePlans() {
        try {
            const response = await HTTPService.get(`${ENDPOINT}/billing/plans`);
            const plans = response.data['plans'];
            setData(LS_KEYS.PLANS, plans);
        } catch (e) {
            console.error('failed to get plans', e);
        }
    }
    public async syncSubscription() {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/subscription`,
                null,
                {
                    'X-Auth-Token': getToken(),
                }
            );
            const subscription = response.data['subscription'];
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            console.error(`failed to get user's subscription details`, e);
        }
    }
    public async buyPaidSubscription(productID) {
        try {
            const response = await this.createCheckoutSession(productID);
            await this.stripe.redirectToCheckout({
                sessionId: response.data['sessionID'],
            });
        } catch (e) {
            console.error('unable to buy subscription', e);
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
                }
            );
            const result: SubscriptionUpdateResponse = response.data['result'];
            switch (result.status) {
                case PAYMENT_INTENT_STATUS.SUCCESS:
                    // subscription updated successfully
                    // no-op required
                    break;
                case PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD:
                    throw new Error(
                        PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD
                    );
                case PAYMENT_INTENT_STATUS.REQUIRE_ACTION:
                    const { error } = await this.stripe.confirmCardPayment(
                        result.clientSecret
                    );
                    if (error) {
                        throw error;
                    }
                    break;
            }
        } catch (e) {
            console.error(e);
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
                }
            );
            const subscription = response.data['subscription'];
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            console.error(e);
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
                }
            );
            const subscription = response.data['subscription'];
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            console.error(e);
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
            }
        );
    }

    public async verifySubscription(
        sessionID: string = null
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
                }
            );
            const subscription = response.data['subscription'];
            setData(LS_KEYS.SUBSCRIPTION, subscription);
            return subscription;
        } catch (err) {
            console.error('Error while verifying subscription', err);
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
                }
            );
            window.location.href = response.data['url'];
        } catch (e) {
            console.error('unable to get customer portal url');
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
                }
            );
            return convertBytesToGBs(response.data.usage);
        } catch (e) {
            console.error('error getting usage', e);
        }
    }
}

export default new billingService();
