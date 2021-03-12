import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
const ENDPOINT = getEndpoint();
import { getToken } from 'utils/common/key';
import { ExecFileOptionsWithStringEncoding } from 'node:child_process';
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
class SubscriptionService {
    private stripe;
    public init() {
        let publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
        this.stripe = window['Stripe'](publishableKey);
    }
    public async getPlans(): Promise<Plan[]> {
        try {
            const response = await HTTPService.get(`${ENDPOINT}/billing/plans`);
            return response.data['plans'];
        } catch (e) {
            console.error('failed to get plans', e);
        }
    }
    public async buySubscription(priceID) {
        try {
            const response = await this.createCheckoutSession(priceID);
            await this.stripe.redirectToCheckout({
                sessionId: response.data['sessionID'],
            });
        } catch (e) {
            console.error(e);
        }
    }

    private async createCheckoutSession(priceId) {
        return HTTPService.post(`${ENDPOINT}/billing/create-checkout-session`, {
            priceId: priceId,
        });
    }

    public async getCheckoutSession(sessionId) {
        try {
            const session = await HTTPService.get(
                `${ENDPOINT}/billing/checkout-session`,
                {
                    sessionId: sessionId,
                }
            );
            return JSON.stringify(session, null, 2);
        } catch (err) {
            console.error('Error when fetching Checkout session', err);
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
}

export default new SubscriptionService();
