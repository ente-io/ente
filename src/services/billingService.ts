import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
const ENDPOINT = getEndpoint();
import { getToken } from 'utils/common/key';
import { runningInBrowser } from 'utils/common/';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { convertBytesToGBs } from 'utils/billingUtil';
import { loadStripe, Stripe } from '@stripe/stripe-js';

export enum PAYMENT_INTENT_STATUS {
    SUCCEEDED = 'succeeded',
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
    isCancelled: boolean;
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
        let publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
        const main = async () => {
            this.stripe = await loadStripe(publishableKey);
        };
        runningInBrowser() && main();
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
    public async buySubscription(productID) {
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
            const subscriptionUpdateResponse: SubscriptionUpdateResponse =
                response.data['subscriptionUpdateResponse'];
            switch (subscriptionUpdateResponse.status) {
                case PAYMENT_INTENT_STATUS.SUCCEEDED:
                    await this.acknowledgeSubscriptionUpdate();
                    break;
                case PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD:
                    throw new Error(
                        PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD
                    );
                case PAYMENT_INTENT_STATUS.REQUIRE_ACTION:
                    const { error } = await this.stripe.confirmCardPayment(
                        subscriptionUpdateResponse.clientSecret
                    );
                    if (error) {
                        throw error;
                    } else {
                        await this.acknowledgeSubscriptionUpdate();
                    }
                    break;
            }
        } catch (e) {
            console.error(e);
            throw e;
        } finally {
            await this.syncSubscription();
        }
    }

    public async cancelSubscription() {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/stripe/cancel-subscription`,
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
        return HTTPService.post(
            `${ENDPOINT}/billing/stripe/checkout-session`,
            {
                productID,
            },
            null,
            {
                'X-Auth-Token': getToken(),
            }
        );
    }

    public async verifySubscription(sessionID): Promise<Subscription> {
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
    private async acknowledgeSubscriptionUpdate() {
        try {
            await HTTPService.post(
                `${ENDPOINT}/billing/stripe/acknowledge-subscription-update`,
                null,
                null,
                {
                    'X-Auth-Token': getToken(),
                }
            );
        } catch (e) {
            console.error('error acknowledging subscription update', e);
        }
    }
}

export default new billingService();
