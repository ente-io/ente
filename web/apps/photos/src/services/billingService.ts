import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import log from "@/base/log";
import { apiURL, paymentsAppOrigin } from "@/base/origins";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    removeData,
    setData,
} from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import isElectron from "is-electron";
import { z } from "zod";

/** Validity of the plan. */
export type PlanPeriod = "month" | "year";

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
    period: PlanPeriod;
}

export interface Plan {
    id: string;
    androidID: string;
    iosID: string;
    storage: number;
    price: string;
    period: PlanPeriod;
    stripeID: string;
}

export interface PlansResponse {
    freePlan: {
        /* Number of bytes available in the free plan */
        storage: number;
    };
    plans: Plan[];
}

class billingService {
    public async getPlans(): Promise<PlansResponse> {
        const token = getToken();
        try {
            let response;
            if (!token) {
                response = await HTTPService.get(
                    await apiURL("/billing/plans/v2"),
                );
            } else {
                response = await HTTPService.get(
                    await apiURL("/billing/user-plans"),
                    null,
                    {
                        "X-Auth-Token": getToken(),
                    },
                );
            }
            return response.data;
        } catch (e) {
            log.error("failed to get plans", e);
        }
    }

    public async buySubscription(productID: string) {
        try {
            const paymentToken = await getPaymentToken();
            await this.redirectToPayments(paymentToken, productID, "buy");
        } catch (e) {
            log.error("unable to buy subscription", e);
            throw e;
        }
    }

    public async updateSubscription(productID: string) {
        try {
            const paymentToken = await getPaymentToken();
            await this.redirectToPayments(paymentToken, productID, "update");
        } catch (e) {
            log.error("subscription update failed", e);
            throw e;
        }
    }

    public async cancelSubscription() {
        try {
            const response = await HTTPService.post(
                await apiURL("/billing/stripe/cancel-subscription"),
                null,
                null,
                {
                    "X-Auth-Token": getToken(),
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            log.error("subscription cancel failed", e);
            throw e;
        }
    }

    public async activateSubscription() {
        try {
            const response = await HTTPService.post(
                await apiURL("/billing/stripe/activate-subscription"),
                null,
                null,
                {
                    "X-Auth-Token": getToken(),
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            log.error("failed to activate subscription", e);
            throw e;
        }
    }

    public async verifySubscription(
        sessionID: string = null,
    ): Promise<Subscription> {
        try {
            const token = getToken();
            if (!token) {
                return;
            }
            const response = await HTTPService.post(
                await apiURL("/billing/verify-subscription"),
                {
                    paymentProvider: "stripe",
                    productID: null,
                    verificationData: sessionID,
                },
                null,
                {
                    "X-Auth-Token": token,
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
            return subscription;
        } catch (e) {
            log.error("Error while verifying subscription", e);
            throw e;
        }
    }

    public async leaveFamily() {
        if (!getToken()) {
            return;
        }
        try {
            await HTTPService.delete(
                await apiURL("/family/leave"),
                null,
                null,
                {
                    "X-Auth-Token": getToken(),
                },
            );
            removeData(LS_KEYS.FAMILY_DATA);
        } catch (e) {
            log.error("/family/leave failed", e);
            throw e;
        }
    }

    public async redirectToPayments(
        paymentToken: string,
        productID: string,
        action: string,
    ) {
        try {
            const redirectURL = this.getRedirectURL();
            window.location.href = `${paymentsAppOrigin()}?productID=${productID}&paymentToken=${paymentToken}&action=${action}&redirectURL=${redirectURL}`;
        } catch (e) {
            log.error("unable to get payments url", e);
            throw e;
        }
    }

    public async redirectToCustomerPortal() {
        try {
            const redirectURL = this.getRedirectURL();
            const response = await HTTPService.get(
                await apiURL("/billing/stripe/customer-portal"),
                { redirectURL },
                {
                    "X-Auth-Token": getToken(),
                },
            );
            window.location.href = response.data.url;
        } catch (e) {
            log.error("unable to get customer portal url", e);
            throw e;
        }
    }

    public getRedirectURL() {
        if (isElectron()) {
            return `${paymentsAppOrigin()}/desktop-redirect`;
        } else {
            return `${window.location.origin}/gallery`;
        }
    }
}

export default new billingService();

/**
 * Fetch and return a one-time token that can be used to authenticate user's
 * requests to the payments app.
 */
const getPaymentToken = async () => {
    const res = await fetch(await apiURL("/users/payment-token"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return z.object({ paymentToken: z.string() }).parse(await res.json())
        .paymentToken;
};
