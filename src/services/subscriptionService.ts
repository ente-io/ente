import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
const ENDPOINT = getEndpoint();
import { getToken } from 'utils/common/key';
import { ExecFileOptionsWithStringEncoding } from 'node:child_process';
import { runningInBrowser } from 'utils/common/utilFunctions';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
export interface Subscription {
    id: number;
    userID: number;
    productID: string;
    storage: number;
    originalTransactionID: string;
    expiryTime: number;
    paymentProvider: string;
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
const FREE_PLAN = 'free';
class SubscriptionService {
    private stripe;
    constructor() {
        let publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
        this.stripe = runningInBrowser() && window['Stripe'](publishableKey);
    }
    public async getPlans(): Promise<Plan[]> {
        try {
            const response = await HTTPService.get(`${ENDPOINT}/billing/plans`);
            return response.data['plans'];
        } catch (e) {
            console.error('failed to get plans', e);
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
        }
    }

    private async createCheckoutSession(productID) {
        return HTTPService.post(
            `${ENDPOINT}/billing/create-checkout-session`,
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
            return response.data['subscription'];
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
            window.location.href = response.data['URL'];
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
            return this.convertBytesToGBs(response.data.usage);
        } catch (e) {
            console.error('error getting usage', e);
        }
    }

    public convertBytesToGBs(bytes): string {
        return (bytes / (1024 * 1024 * 1024)).toFixed(2);
    }
    public isOnFreePlan() {
        const subscription: Subscription = getData(LS_KEYS.SUBSCRIPTION);
        return subscription?.productID === FREE_PLAN;
    }
}

export default new SubscriptionService();
