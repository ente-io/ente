import { getEndpoint, getPaymentsUrl } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import { setData, LS_KEYS } from 'utils/storage/localStorage';
import { convertToHumanReadable } from 'utils/billingUtil';
import HTTPService from './HTTPService';
import { logError } from 'utils/sentry';
import { getPaymentToken } from './userService';

const ENDPOINT = getEndpoint();

enum PaymentActionType {
    Buy = 'buy',
    Update = 'update',
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
    price: string;
    period: string;
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

export const FREE_PLAN = 'free';
class billingService {
    public async getPlans(): Promise<Plan[]> {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/plans/v2`
            );
            const { plans } = response.data;
            return plans;
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
                }
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            logError(e, "failed to get user's subscription details");
        }
    }

    public async buySubscription(productID: string) {
        try {
            const paymentToken = await getPaymentToken();
            await this.redirectToPayments(
                paymentToken,
                productID,
                PaymentActionType.Buy
            );
        } catch (e) {
            logError(e, 'unable to buy subscription');
            throw e;
        }
    }

    public async updateSubscription(productID: string) {
        try {
            const paymentToken = await getPaymentToken();
            await this.redirectToPayments(
                paymentToken,
                productID,
                PaymentActionType.Update
            );
        } catch (e) {
            logError(e, 'subscription update failed');
            throw e;
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
                }
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            logError(e);
            throw e;
        }
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
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
            return subscription;
        } catch (err) {
            logError(err, 'Error while verifying subscription');
            throw err;
        }
    }

    public async redirectToPayments(
        paymentToken: string,
        productID: string,
        action: string
    ) {
        try {
            window.location.href = `${getPaymentsUrl()}?productID=${productID}&paymentToken=${paymentToken}&action=${action}&redirectURL=${
                window.location.origin
            }/gallery`;
        } catch (e) {
            logError(e, 'unable to get payments url');
            throw e;
        }
    }

    public async redirectToCustomerPortal() {
        try {
            const response = await HTTPService.get(
                `${ENDPOINT}/billing/stripe/customer-portal`,
                { redirectURL: `${window.location.origin}/gallery` },
                {
                    'X-Auth-Token': getToken(),
                }
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
                }
            );
            return convertToHumanReadable(response.data.usage);
        } catch (e) {
            logError(e, 'error getting usage');
        }
    }
}

export default new billingService();
