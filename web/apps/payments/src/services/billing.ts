import { loadStripe } from "@stripe/stripe-js";

/**
 * Communicate with Stripe using their JS SDK, and redirect back to the client.
 *
 * All necessary parameters are obtained by parsing the request parameters.
 *
 * In case of unrecoverable errors, this function will throw. Otherwise it will
 * redirect to the client or to some fallback URL.
 */
export const parseAndHandleRequest = async () => {
    // See: [Note: Intercept payments redirection to desktop app]
    if (window.location.pathname == "/desktop-redirect") {
        const desktopRedirectURL = new URL("ente://app/gallery");
        desktopRedirectURL.search = new URL(window.location.href).search;
        window.location.href = desktopRedirectURL.href;
        return;
    }

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

const apiOrigin = import.meta.env.VITE_ENTE_ENDPOINT ?? "https://api.ente.io";

type StripeAccountCountry = "US" | "IN";

const isStripeAccountCountry = (c: unknown): c is StripeAccountCountry =>
    c == "US" || c == "IN";

const stripePublishableKey = (accountCountry: StripeAccountCountry) => {
    switch (accountCountry) {
        case "US":
            return (
                import.meta.env.VITE_STRIPE_US_PUBLISHABLE_KEY ??
                "pk_live_51LZ9P4G1ITnQlpAnrP6pcS7NiuJo3SnJ7gibjJlMRatkrd2EY1zlMVTVQG5RkSpLPbsHQzFfnEtgHnk1PiylIFkk00tC0LWXwi"
            );
        case "IN":
            return (
                import.meta.env.VITE_STRIPE_IN_PUBLISHABLE_KEY ??
                "pk_live_51HAhqDK59oeucIMOiTI6MDDM2UWUbCAJXJCGsvjJhiO8nYJz38rQq5T4iyQLDMKxqEDUfU5Hopuj4U5U4dff23oT00fHvZeodC"
            );
    }
};

/** Return the {@link StripeAccountCountry} for the user. */
const getUserStripeAccountCountry = async (paymentToken: string) => {
    const url = `${apiOrigin}/billing/stripe-account-country`;
    const res = await fetch(url, { headers: { "X-Auth-Token": paymentToken } });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const json: unknown = await res.json();
    if (json && typeof json === "object" && "stripeAccountCountry" in json) {
        const c = json.stripeAccountCountry;
        if (isStripeAccountCountry(c)) return c;
    }
    throw new Error(`Unexpected response for ${url}: ${JSON.stringify(json)}`);
};

/** Load and return the Stripe JS SDK initialized for the given country. */
const getStripe = async (
    redirectURL: string,
    accountCountry: StripeAccountCountry,
) => {
    const publishableKey = stripePublishableKey(accountCountry);
    try {
        const stripe = await loadStripe(publishableKey);
        if (!stripe) throw new Error("Failed to load Stripe");
        return stripe;
    } catch (e) {
        redirectToApp(redirectURL, "fail", "stripe_error");
        throw e;
    }
};

/** The flow when the user wants to buy a new subscription. */
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
        redirectToApp(redirectURL, "fail", "server_error");
        throw e;
    }
};

/** Create a new checkout session on museum and return the sessionID. */
const createCheckoutSession = async (
    productID: string,
    paymentToken: string,
    redirectURL: string,
): Promise<string> => {
    const params = new URLSearchParams({ productID, redirectURL });
    const url = `${apiOrigin}/billing/stripe/checkout-session?${params.toString()}`;
    const res = await fetch(url, { headers: { "X-Auth-Token": paymentToken } });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const json: unknown = await res.json();
    if (json && typeof json == "object" && "sessionID" in json) {
        const sid = json.sessionID;
        if (typeof sid == "string") return sid;
    }
    throw new Error(`Unexpected response for ${url}: ${JSON.stringify(json)}`);
};

const updateSubscription = async (
    productID: string,
    paymentToken: string,
    redirectURL: string,
) => {
    try {
        const accountCountry = await getUserStripeAccountCountry(paymentToken);
        const stripe = await getStripe(redirectURL, accountCountry);
        const { status, clientSecret } = await updateStripeSubscription(
            paymentToken,
            productID,
        );
        switch (status) {
            case "success": {
                // Subscription was updated successfully, nothing more required
                redirectToApp(redirectURL, "success");
                return;
            }

            case "requires_payment_method":
                redirectToApp(redirectURL, "fail", "requires_payment_method");
                return;

            case "requires_action": {
                const { error } = await stripe.confirmCardPayment(clientSecret);
                if (!error) {
                    redirectToApp(redirectURL, "success");
                } else {
                    console.error("Failed to confirm card payment", error);
                    if (error.type == "card_error") {
                        redirectToApp(
                            redirectURL,
                            "fail",
                            "requires_payment_method",
                        );
                    } else if (
                        error.type == "authentication_error" ||
                        error.code == "payment_intent_authentication_failure"
                    ) {
                        redirectToApp(
                            redirectURL,
                            "fail",
                            "authentication_failed",
                        );
                    } else {
                        redirectToApp(redirectURL, "fail");
                    }
                }
                return;
            }
        }
    } catch (e) {
        redirectToApp(redirectURL, "fail", "server_error");
        throw e;
    }
};

type PaymentStatus = "success" | "requires_action" | "requires_payment_method";

const isPaymentStatus = (s: unknown): s is PaymentStatus =>
    s == "success" || s == "requires_action" || s == "requires_payment_method";

interface UpdateStripeSubscriptionResponse {
    status: PaymentStatus;
    clientSecret: string;
}

/**
 * Make a request to museum to update an existing Stripe subscription with
 * {@link productID} for the user.
 */
async function updateStripeSubscription(
    paymentToken: string,
    productID: string,
): Promise<UpdateStripeSubscriptionResponse> {
    const url = `${apiOrigin}/billing/stripe/update-subscription`;
    const res = await fetch(url, {
        method: "POST",
        headers: { "X-Auth-Token": paymentToken },
        body: JSON.stringify({ productID }),
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

type RedirectStatus = "success" | "fail";

type FailureReason =
    /**
     * Unable to authenticate card or 3DS.
     *
     * User should be shown button for fixing card via customer portal.
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

/**
 * Navigate to {@link redirectURL}, passing the given values as query params.
 *
 * [Note: Redirects do not interrupt script execution]
 *
 * I have been unable to find a documentation / reference source for this, but
 * in practice when I test it with a following snippet
 *
 *     const nonce = Math.random();
 *     console.log("before", nonce);
 *     window.location.href = "http://example.org";
 *     console.log("after", nonce);
 *
 * I observe that the code after the navigation also runs.
 */
const redirectToApp = (
    redirectURL: string,
    status: RedirectStatus,
    reason?: FailureReason,
) => {
    // [Note: Intercept payments redirection to desktop app]
    //
    // The desktop app passes "<our-origin>/desktop-redirect" as `redirectURL`.
    // This is just a placeholder, we want to intercept this and instead
    // redirect to the ente:// scheme protocol handler that is internally being
    // used by the desktop app.
    if (new URL(redirectURL).pathname == "/desktop-redirect") {
        redirectToApp("ente://app/gallery", status, reason);
        return;
    }

    let url = `${redirectURL}?status=${status}`;
    if (reason) url = `${url}&reason=${reason}`;
    window.location.href = url;
};

const redirectHome = () => {
    window.location.href = "https://ente.io";
};
