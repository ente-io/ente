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
    private productID;
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
    public async buySubscription(productID) {
        try {
            this.productID = productID;
            const response = await this.createCheckoutSession();
            await this.stripe.redirectToCheckout({
                sessionId: response.data['sessionID'],
            });
        } catch (e) {
            console.error('unable to buy subscription', e);
        }
    }

    private async createCheckoutSession() {
        return HTTPService.post(`${ENDPOINT}/billing/create-checkout-session`, {
            productID: this.productID,
        });
    }

    public async verifySubscription(sessionID): Promise<Subscription> {
        try {
            const response = await HTTPService.post(
                `${ENDPOINT}/billing/verify-subscription`,
                {
                    paymentProvider: 'stripe',
                    productID: this.productID,
                    VerificationData: sessionID,
                },
                null,
                {
                    'X-Auth-Token': getToken(),
                }
            );
            console.log(response.data['subscription']);
            return response.data['subscription'];
        } catch (err) {
            console.error('Error while verifying subscription', err);
        }
    }

    public async redirectToCustomerPortal() {
        return null;
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
