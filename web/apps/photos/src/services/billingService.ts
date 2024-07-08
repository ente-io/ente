import log from "@/next/log";
import { apiURL, paymentsAppOrigin } from "@/next/origins";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    removeData,
    setData,
} from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import isElectron from "is-electron";
import { Plan, Subscription } from "types/billing";
import { getPaymentToken } from "./userService";

enum PaymentActionType {
    Buy = "buy",
    Update = "update",
}

export interface FreePlan {
    /* Number of bytes available in the free plan */
    storage: number;
}

export interface PlansResponse {
    freePlan: FreePlan;
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

    public async syncSubscription() {
        try {
            const response = await HTTPService.get(
                await apiURL("/billing/subscription"),
                null,
                {
                    "X-Auth-Token": getToken(),
                },
            );
            const { subscription } = response.data;
            setData(LS_KEYS.SUBSCRIPTION, subscription);
        } catch (e) {
            log.error("failed to get user's subscription details", e);
        }
    }

    public async buySubscription(productID: string) {
        try {
            const paymentToken = await getPaymentToken();
            await this.redirectToPayments(
                paymentToken,
                productID,
                PaymentActionType.Buy,
            );
        } catch (e) {
            log.error("unable to buy subscription", e);
            throw e;
        }
    }

    public async updateSubscription(productID: string) {
        try {
            const paymentToken = await getPaymentToken();
            await this.redirectToPayments(
                paymentToken,
                productID,
                PaymentActionType.Update,
            );
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
