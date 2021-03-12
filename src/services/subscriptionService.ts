import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
const ENDPOINT = getEndpoint();
import { getToken } from 'utils/common/key';
export interface Subscription {
    id: number;
    userID: number;
    productID: string;
    storage: number;
    originalTransactionID: string;
    expiryTime: number;
    paymentProvider: string;
}
class SubscriptionService {
    private stripe;
    public init() {
        let publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
        this.stripe = window['Stripe'](publishableKey);
    }
    public async buySubscription() {
        try {
            const priceId = 'price_1IT1DPK59oeucIMOiYs1P6Xd';
            const response = await this.createCheckoutSession(priceId);
            console.log(response.data);
            const result = await this.stripe.redirectToCheckout({
                sessionId: response.data.sessionId,
            });
            console.log(result);
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
                `${ENDPOINT}/billing/checkout-session?sessionId= ${sessionId}`
            );
            return JSON.stringify(session, null, 2);
        } catch (err) {
            console.log('Error when fetching Checkout session', err);
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
