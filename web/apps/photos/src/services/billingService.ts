import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import log from "@/base/log";
import { apiURL, paymentsAppOrigin } from "@/base/origins";
import { nullToUndefined } from "@/utils/transform";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    LS_KEYS,
    removeData,
    setData,
} from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import isElectron from "is-electron";
import { z } from "zod";

const PlanPeriod = z.enum(["month", "year"]);

/**
 * Validity of the plan.
 */
export type PlanPeriod = z.infer<typeof PlanPeriod>;

const Subscription = z.object({
    productID: z.string(),
    storage: z.number(),
    expiryTime: z.number(),
    paymentProvider: z.string(),
    attributes: z
        .object({
            isCancelled: z.boolean().nullish().transform(nullToUndefined),
        })
        .nullish()
        .transform(nullToUndefined),
    price: z.string(),
    period: PlanPeriod,
});

/**
 * Details about the user's subscription.
 */
export type Subscription = z.infer<typeof Subscription>;

/**
 * Zod schema for an individual plan received in the list of plans.
 */
const Plan = z.object({
    id: z.string(),
    androidID: z.string().nullish().transform(nullToUndefined),
    iosID: z.string().nullish().transform(nullToUndefined),
    stripeID: z.string().nullish().transform(nullToUndefined),
    storage: z.number(),
    price: z.string(),
    period: PlanPeriod,
});

/**
 * An individual plan received in the list of plans from remote.
 */
export type Plan = z.infer<typeof Plan>;

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
}

export default new billingService();

/**
 * Start the flow to purchase or update a subscription by redirecting the user
 * to the payments app.
 *
 * @param productID The Stripe product ID of the plan to purchase.
 *
 * @param action buy or update.
 */
export const redirectToPaymentsApp = async (
    productID: string,
    action: "buy" | "update",
) => {
    const paymentToken = await getPaymentToken();
    const redirectURL = completionRedirectURL();
    window.location.href = `${paymentsAppOrigin()}?productID=${productID}&paymentToken=${paymentToken}&action=${action}&redirectURL=${redirectURL}`;
};

/**
 * Return the URL to which the payments app should redirect back on completion
 * of the flow.
 */
const completionRedirectURL = () =>
    isElectron()
        ? `${paymentsAppOrigin()}/desktop-redirect`
        : `${window.location.origin}/gallery`;

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

/**
 * Redirect to the Stripe customer portal / dashboard where the user can view
 * details about their subscription and modify their payment method.
 */
export const redirectToCustomerPortal = async () => {
    const redirectURL = completionRedirectURL();
    const url = await apiURL("/billing/stripe/customer-portal");
    const params = new URLSearchParams({ redirectURL });
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const data = z
        .object({ data: z.object({ url: z.string() }) })
        .parse(await res.json()).data;
    window.location.href = data.url;
};
