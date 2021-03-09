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
}

export default new SubscriptionService();
