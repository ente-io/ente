import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from './HTTPService';
const ENDPOINT = getEndpoint();

class SubscriptionService {
    private stripe;
    public init() {
        let publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
        this.stripe = Stripe(publishableKey);
    }
    public async buySubscription() {
        try {
            const priceId = 'price_1IT1GfK59oeucIMOZXxQCayi';
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
}

export default new SubscriptionService();
