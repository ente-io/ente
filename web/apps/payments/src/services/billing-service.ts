// TODO: Audit this and other eslints
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-confusing-void-expression */
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-enum-comparison */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */

import { loadStripe } from "@stripe/stripe-js";

/**
 * Communicate with Stripe using their JS SDK, and redirect back to the client
 *
 * All necessary parameters are obtained by parsing the request parameters.
 *
 * In case of unrecoverable errors, this function will throw. Otherwise it will
 * redirect to the client or to some fallback URL.
 */
export const parseAndHandleRequest = async () => {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const productID = urlParams.get("productID");
        const paymentToken = urlParams.get("paymentToken");
        const action = urlParams.get("action");
        const redirectURL = urlParams.get("redirectURL");

        if (!action && !paymentToken && !productID && !redirectURL) {
            // Maybe someone attempted to directly open this page in their
            // browser. Not much we can do, just redirect them to the main site.
            console.log(
                "None of the required query parameters were supplied, redirecting to the ente.io",
            );
            redirectHome();
            return;
        }

        if (!action || !paymentToken || !productID || !redirectURL) {
            throw Error("Required query parameter was not provided");
        }

        switch (action) {
            case "buy":
                await buySubscription(productID, paymentToken, redirectURL);
                break;
            case "update":
                await updateSubscription(productID, paymentToken, redirectURL);
                break;
            default:
                throw Error(`Unsupported action ${action}`);
        }
    } catch (e) {
        console.error(e);
        throw e;
    }
};

const apiHost = process.env.NEXT_PUBLIC_ENTE_ENDPOINT ?? "https://api.ente.io";

type StripeAccountCountry = "IN" | "US";

const isStripeAccountCountry = (c: unknown): c is StripeAccountCountry => {
    if (c == "IN" || c == "US") return true;
    return false;
};

const stripePublishableKey = (accountCountry: StripeAccountCountry) => {
    switch (accountCountry) {
        case "IN":
            return (
                process.env.NEXT_PUBLIC_STRIPE_IN_PUBLISHABLE_KEY ??
                "pk_live_51HAhqDK59oeucIMOiTI6MDDM2UWUbCAJXJCGsvjJhiO8nYJz38rQq5T4iyQLDMKxqEDUfU5Hopuj4U5U4dff23oT00fHvZeodC"
            );
        case "US":
            return (
                process.env.NEXT_PUBLIC_STRIPE_US_PUBLISHABLE_KEY ??
                "pk_live_51LZ9P4G1ITnQlpAnrP6pcS7NiuJo3SnJ7gibjJlMRatkrd2EY1zlMVTVQG5RkSpLPbsHQzFfnEtgHnk1PiylIFkk00tC0LWXwi"
            );
    }
};

type RedirectStatus = "success" | "fail";

type FailureReason =
    /**
     * Unable to authenticate card or 3DS
     *
     * User should be shown button for fixing card via customer portal
     */
    | "authentication_failed"
    /**
     * Card declined results in this error.
     *
     * Show button to the customer portal.
     */
    | "requires_payment_method"
    /**
     * An error in initializing the Stripe JS SDK.
     */
    | "stripe_error"
    | "canceled"
    | "server_error";

/** Return the {@link StripeAccountCountry} for the user */
const getUserStripeAccountCountry = async (
    paymentToken: string,
): Promise<StripeAccountCountry> => {
    const url = `${apiHost}/billing/stripe-account-country`;
    const res = await fetch(url, {
        headers: {
            "X-Auth-Token": paymentToken,
        },
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const json: unknown = await res.json();
    if (json && typeof json === "object" && "stripeAccountCountry" in json) {
        const c = json.stripeAccountCountry;
        if (isStripeAccountCountry(c)) return c;
    }
    throw new Error(`Unexpected response for ${url}: ${JSON.stringify(json)}`);
};

/** Load and return the Stripe JS SDK initialized for the given country */
const getStripe = async (
    redirectURL: string,
    accountCountry: StripeAccountCountry,
) => {
    const publishableKey = stripePublishableKey(accountCountry);
    try {
        const stripe = await loadStripe(publishableKey);
        if (!stripe) throw new Error("Stripe returned null");
        return stripe;
    } catch (e) {
        console.error("Failed to load Stripe", e);
        redirectToApp(redirectURL, "fail", "stripe_error");
        throw e;
    }
};

/** The flow when the user wants to buy a new subscription */
const buySubscription = async (
    productID: string,
    paymentToken: string,
    redirectURL: string,
) => {
    try {
        const accountCountry = await getUserStripeAccountCountry(paymentToken);
        const stripe = await getStripe(redirectURL, accountCountry);
        const sessionId = await createCheckoutSession(
            productID,
            paymentToken,
            redirectURL,
        );
        await stripe.redirectToCheckout({ sessionId });
    } catch (e) {
        console.log("Subscription purchase failed", e);
        redirectToApp(redirectURL, "fail", "server_error");
        throw e;
    }
};

/** Create a new checkout session on museum and return the sessionID */
const createCheckoutSession = async (
    productID: string,
    paymentToken: string,
    redirectURL: string,
): Promise<string> => {
    const params = new URLSearchParams({ productID, redirectURL });
    const url = `${apiHost}/billing/stripe/checkout-session?${params.toString()}`;
    const res = await fetch(url, {
        headers: {
            "X-Auth-Token": paymentToken,
        },
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const json: unknown = await res.json();
    if (json && typeof json == "object" && "sessionID" in json) {
        const sid = json.sessionID;
        if (typeof sid == "string") return sid;
    }
    throw new Error(`Unexpected response for ${url}: ${JSON.stringify(json)}`);
};

export async function updateSubscription(
    productID: string,
    paymentToken: string,
    redirectURL: string,
) {
    try {
        const accountCountry = await getUserStripeAccountCountry(paymentToken);
        const stripe = await getStripe(redirectURL, accountCountry);
        const { status, clientSecret } = await updateStripeSubscription(
            paymentToken,
            productID,
        );
        switch (status) {
            case "success":
                // Subscription was updated successfully, nothing more required
                return redirectToApp(redirectURL, "success");

            case "requires_payment_method":
                return redirectToApp(
                    redirectURL,
                    "fail",
                    "requires_payment_method",
                );

            case "requires_action": {
                const { error } = await stripe.confirmCardPayment(clientSecret);
                if (!error) {
                    return redirectToApp(redirectURL, "success");
                } else {
                    console.error("Failed to confirm card payment", error);
                    if (error.type == "card_error") {
                        return redirectToApp(
                            redirectURL,
                            "fail",
                            "requires_payment_method",
                        );
                    } else if (
                        error.type == "authentication_error" ||
                        error.code == "payment_intent_authentication_failure"
                    ) {
                        return redirectToApp(
                            redirectURL,
                            "fail",
                            "authentication_failed",
                        );
                    } else {
                        return redirectToApp(redirectURL, "fail");
                    }
                }
            }
        }
    } catch (e) {
        console.log("Subscription update failed", e);
        redirectToApp(redirectURL, "fail", "server_error");
        throw e;
    }
}

type PaymentStatus = "success" | "requires_action" | "requires_payment_method";

const isPaymentStatus = (s: unknown): s is PaymentStatus =>
    s == "success" || s == "requires_action" || s == "requires_payment_method";

interface UpdateStripeSubscriptionResponse {
    status: PaymentStatus;
    clientSecret: string;
}

/**
 * Make a request to museum to update an existing Stript subscription with
 * {@link productID} for the user.
 */
async function updateStripeSubscription(
    paymentToken: string,
    productID: string,
): Promise<UpdateStripeSubscriptionResponse> {
    const url = `${apiHost}/billing/stripe/update-subscription`;
    const res = await fetch(url, {
        method: "POST",
        headers: {
            "X-Auth-Token": paymentToken,
        },
        body: JSON.stringify({
            productID,
        }),
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const json: unknown = await res.json();
    if (json && typeof json == "object" && "result" in json) {
        const result = json.result;
        if (
            result &&
            typeof result == "object" &&
            "status" in result &&
            "clientSecret" in result
        ) {
            const status = result.status;
            const clientSecret = result.clientSecret;
            if (isPaymentStatus(status) && typeof clientSecret == "string") {
                return { status, clientSecret };
            }
        }
    }
    throw new Error(`Unexpected response for ${url}: ${JSON.stringify(json)}`);
}

const redirectToApp = (
    redirectURL: string,
    status: RedirectStatus,
    reason?: FailureReason,
) => {
    let url = `${redirectURL}?status=${status}`;
    if (reason) url = `${url}&reason=${reason}`;
    window.location.href = url;
};

const redirectHome = () => {
    window.location.href = "https://ente.io";
};
