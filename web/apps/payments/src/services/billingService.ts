// TODO: Audit this and other eslints
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-confusing-void-expression */
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-enum-comparison */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */

import { loadStripe } from "@stripe/stripe-js";
import { CUSTOM_ERROR } from "utils/error";
import { logError } from "utils/log";
import HTTPService from "./HTTPService";

const getStripePublishableKey = (stripeAccount: StripeAccountCountry) => {
    if (stripeAccount === StripeAccountCountry.STRIPE_IN) {
        return (
            process.env.NEXT_PUBLIC_STRIPE_IN_PUBLISHABLE_KEY ??
            "pk_live_51HAhqDK59oeucIMOiTI6MDDM2UWUbCAJXJCGsvjJhiO8nYJz38rQq5T4iyQLDMKxqEDUfU5Hopuj4U5U4dff23oT00fHvZeodC"
        );
    } else if (stripeAccount === StripeAccountCountry.STRIPE_US) {
        return (
            process.env.NEXT_PUBLIC_STRIPE_US_PUBLISHABLE_KEY ??
            "pk_live_51LZ9P4G1ITnQlpAnrP6pcS7NiuJo3SnJ7gibjJlMRatkrd2EY1zlMVTVQG5RkSpLPbsHQzFfnEtgHnk1PiylIFkk00tC0LWXwi"
        );
    } else {
        throw Error("stripe account not found");
    }
};

const getEndpoint = () => {
    const endPoint =
        process.env.NEXT_PUBLIC_ENTE_ENDPOINT ?? "https://api.ente.io";
    return endPoint;
};
enum PAYMENT_INTENT_STATUS {
    SUCCESS = "success",
    REQUIRE_ACTION = "requires_action",
    REQUIRE_PAYMENT_METHOD = "requires_payment_method",
}

enum FAILURE_REASON {
    // Unable to authenticate card or 3DS
    // User should be showing button for fixing card via customer portal
    AUTHENTICATION_FAILED = "authentication_failed",
    // Card declined result in this error. Show button to the customer portal.
    REQUIRE_PAYMENT_METHOD = "requires_payment_method",
    STRIPE_ERROR = "stripe_error",
    CANCELED = "canceled",
    SERVER_ERROR = "server_error",
}

enum STRIPE_ERROR_TYPE {
    CARD_ERROR = "card_error",
    AUTHENTICATION_ERROR = "authentication_error",
}

enum STRIPE_ERROR_CODE {
    AUTHENTICATION_ERROR = "payment_intent_authentication_failure",
}

enum RESPONSE_STATUS {
    success = "success",
    fail = "fail",
}

enum PaymentActionType {
    Buy = "buy",
    Update = "update",
}

enum StripeAccountCountry {
    STRIPE_IN = "IN",
    STRIPE_US = "US",
}

interface SubscriptionUpdateResponse {
    result: {
        status: PAYMENT_INTENT_STATUS;
        clientSecret: string;
    };
}

export async function parseAndHandleRequest() {
    try {
        const urlParams = new URLSearchParams(window.location.search);
        const productID = urlParams.get("productID");
        const paymentToken = urlParams.get("paymentToken");
        const action = urlParams.get("action");
        const redirectURL = urlParams.get("redirectURL");
        if (!action && !paymentToken && !productID && !redirectURL) {
            throw Error(CUSTOM_ERROR.DIRECT_OPEN_WITH_NO_QUERY_PARAMS);
        } else if (!action || !paymentToken || !productID || !redirectURL) {
            throw Error(CUSTOM_ERROR.MISSING_REQUIRED_QUERY_PARAM);
        }
        switch (action) {
            case PaymentActionType.Buy:
                await buyPaidSubscription(productID, paymentToken, redirectURL);
                break;
            case PaymentActionType.Update:
                await updateSubscription(productID, paymentToken, redirectURL);
                break;
            default:
                throw Error(CUSTOM_ERROR.INVALID_ACTION);
        }
    } catch (e: any) {
        console.error("Error: ", JSON.stringify(e));
        if (e.message !== CUSTOM_ERROR.DIRECT_OPEN_WITH_NO_QUERY_PARAMS) {
            logError(e);
        }
        throw e;
    }
}

async function getUserStripeAccountCountry(
    paymentToken: string,
): Promise<{ stripeAccountCountry: StripeAccountCountry }> {
    const response = await HTTPService.get(
        `${getEndpoint()}/billing/stripe-account-country`,
        undefined,
        {
            "X-Auth-Token": paymentToken,
        },
    );
    return response.data;
}

async function getStripe(
    redirectURL: string,
    stripeAccount: StripeAccountCountry,
) {
    try {
        const publishableKey = getStripePublishableKey(stripeAccount);
        const stripe = await loadStripe(publishableKey);

        if (!stripe) {
            throw Error("stripe load failed");
        }
        return stripe;
    } catch (e) {
        logError(e, "stripe load failed");
        redirectToApp(
            redirectURL,
            RESPONSE_STATUS.fail,
            FAILURE_REASON.STRIPE_ERROR,
        );
        throw e;
    }
}

export async function buyPaidSubscription(
    productID: string,
    paymentToken: string,
    redirectURL: string,
) {
    try {
        const { stripeAccountCountry } =
            await getUserStripeAccountCountry(paymentToken);
        const stripe = await getStripe(redirectURL, stripeAccountCountry);
        const { sessionID } = await createCheckoutSession(
            productID,
            paymentToken,
            redirectURL,
        );
        await stripe.redirectToCheckout({
            sessionId: sessionID,
        });
    } catch (e) {
        logError(e, "subscription purchase failed");
        redirectToApp(
            redirectURL,
            RESPONSE_STATUS.fail,
            FAILURE_REASON.SERVER_ERROR,
        );
        throw e;
    }
}

async function createCheckoutSession(
    productID: string,
    paymentToken: string,
    redirectURL: string,
): Promise<{ sessionID: string }> {
    const response = await HTTPService.get(
        `${getEndpoint()}/billing/stripe/checkout-session`,
        {
            productID,
            redirectURL,
        },
        {
            "X-Auth-Token": paymentToken,
        },
    );
    return response.data;
}

export async function updateSubscription(
    productID: string,
    paymentToken: string,
    redirectURL: string,
) {
    try {
        const { stripeAccountCountry } =
            await getUserStripeAccountCountry(paymentToken);
        const stripe = await getStripe(redirectURL, stripeAccountCountry);
        const { result } = await subscriptionUpdateRequest(
            paymentToken,
            productID,
        );
        switch (result.status) {
            case PAYMENT_INTENT_STATUS.SUCCESS:
                // subscription updated successfully
                // no-op required
                return redirectToApp(redirectURL, RESPONSE_STATUS.success);

            case PAYMENT_INTENT_STATUS.REQUIRE_PAYMENT_METHOD:
                return redirectToApp(
                    redirectURL,
                    RESPONSE_STATUS.fail,
                    FAILURE_REASON.REQUIRE_PAYMENT_METHOD,
                );
            case PAYMENT_INTENT_STATUS.REQUIRE_ACTION: {
                const { error } = await stripe.confirmCardPayment(
                    result.clientSecret,
                );
                if (error) {
                    logError(
                        error,
                        `${error.message} - subscription update failed`,
                    );
                    if (error.type === STRIPE_ERROR_TYPE.CARD_ERROR) {
                        return redirectToApp(
                            redirectURL,
                            RESPONSE_STATUS.fail,
                            FAILURE_REASON.REQUIRE_PAYMENT_METHOD,
                        );
                    } else if (
                        error.type === STRIPE_ERROR_TYPE.AUTHENTICATION_ERROR ||
                        error.code === STRIPE_ERROR_CODE.AUTHENTICATION_ERROR
                    ) {
                        return redirectToApp(
                            redirectURL,
                            RESPONSE_STATUS.fail,
                            FAILURE_REASON.AUTHENTICATION_FAILED,
                        );
                    } else {
                        return redirectToApp(redirectURL, RESPONSE_STATUS.fail);
                    }
                } else {
                    return redirectToApp(redirectURL, RESPONSE_STATUS.success);
                }
            }
        }
    } catch (e) {
        logError(e, "subscription update failed");
        redirectToApp(
            redirectURL,
            RESPONSE_STATUS.fail,
            FAILURE_REASON.SERVER_ERROR,
        );
        throw e;
    }
}

async function subscriptionUpdateRequest(
    paymentToken: string,
    productID: string,
): Promise<SubscriptionUpdateResponse> {
    const response = await HTTPService.post(
        `${getEndpoint()}/billing/stripe/update-subscription`,
        {
            productID,
        },
        undefined,
        {
            "X-Auth-Token": paymentToken,
        },
    );
    return response.data;
}

function redirectToApp(redirectURL: string, status: string, reason?: string) {
    let completePath = `${redirectURL}?status=${status}`;
    if (reason) {
        completePath = `${completePath}&reason=${reason}`;
    }
    window.location.href = completePath;
}
