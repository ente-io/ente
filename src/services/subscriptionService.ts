import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
const ENDPOINT = getEndpoint();
import { getToken } from 'utils/common/key';
import { runningInBrowser } from 'utils/common/utilFunctions';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { convertBytesToGBs } from 'utils/billingUtil';
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
    androidID: string;
    iosID: string;
    storage: number;
    price: string;
    period: string;
    stripeID: string;
}
export const FREE_PLAN = 'free';
class SubscriptionService {
    private stripe;
    constructor() {
        let publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
        this.stripe = runningInBrowser() && window['Stripe'](publishableKey);
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
            const subscription = response.data['subscription'];
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            console.log(e);
            throw e;
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
            console.log(subscription);
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            console.log(e);
            throw e;
        }
    }

    private async createCheckoutSession(productID) {
        return HTTPService.post(
            `${ENDPOINT}/billing/stripe/create-checkout-session`,
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
                `${ENDPOINT}/billing/customer-portal`,
                null,
                {
                    'X-Auth-Token': getToken(),
                }
            );
            window.location.href = response.data['url'];
        } catch (e) {
            console.error('unable to get customer portal url');
        }
    }
    async getUsage() {
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

export default new SubscriptionService();
