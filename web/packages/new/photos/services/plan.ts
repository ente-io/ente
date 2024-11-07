// TODO:
/* eslint-disable @typescript-eslint/prefer-optional-chain */
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL, paymentsAppOrigin } from "@/base/origins";
import {
    familyUsage,
    getTotalFamilyUsage,
    isPartOfFamily,
} from "@/new/photos/services/family";
import { nullToUndefined } from "@/utils/transform";
import { LS_KEYS, setData } from "@ente/shared/storage/localStorage";
import isElectron from "is-electron";
import { z } from "zod";
import type { BonusData, UserDetails } from "./user";

const PlanPeriod = z.enum(["month", "year"]);

/**
 * Validity of the plan.
 */
export type PlanPeriod = z.infer<typeof PlanPeriod>;

export const Subscription = z.object({
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
    // TODO: We get back subscriptions without a period on cancel / reactivate.
    // Handle them better, or remove this TODO.
    period: z.enum(["month", "year", ""]).transform((s) => (s ? s : "month")),
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

const PlansData = z.object({
    freePlan: z.object({
        /* Number of bytes available in the free plan */
        storage: z.number(),
    }),
    plans: z.array(Plan),
});

export type PlansData = z.infer<typeof PlansData>;

/**
 * Fetch the list of plans from remote.
 */
export const getPlansData = async (): Promise<PlansData> => {
    const res = await fetch(await apiURL("/billing/user-plans"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return PlansData.parse(await res.json());
};

/**
 * Derive the total usage for the user both when they are on an individual plan,
 * or on a family plan.
 */
export const planUsage = (userDetails: UserDetails) =>
    isPartOfFamily(userDetails) ? familyUsage(userDetails) : userDetails.usage;

const SubscriptionResponse = z.object({
    subscription: Subscription,
});

export const verifySubscription = async (
    sessionID: string,
): Promise<Subscription> => {
    const res = await fetch(await apiURL("/billing/verify-subscription"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({
            paymentProvider: "stripe",
            productID: null,
            verificationData: sessionID,
        }),
    });
    ensureOk(res);
    const { subscription } = SubscriptionResponse.parse(await res.json());
    setData(LS_KEYS.SUBSCRIPTION, subscription);
    return subscription;
};

export const activateSubscription = async () => {
    const res = await fetch(
        await apiURL("/billing/stripe/activate-subscription"),
        {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        },
    );
    ensureOk(res);
    const { subscription } = SubscriptionResponse.parse(await res.json());
    setData(LS_KEYS.SUBSCRIPTION, subscription);
};

export const cancelSubscription = async () => {
    const res = await fetch(
        await apiURL("/billing/stripe/cancel-subscription"),
        {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        },
    );
    ensureOk(res);
    const { subscription } = SubscriptionResponse.parse(await res.json());
    setData(LS_KEYS.SUBSCRIPTION, subscription);
};

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
    const portal = z.object({ url: z.string() }).parse(await res.json());
    window.location.href = portal.url;
};

/**
 * Return true if the given {@link Subscription} has not expired.
 */
export const isSubscriptionActive = (subscription: Subscription) =>
    subscription && subscription.expiryTime > Date.now() * 1000;

/**
 * Return true if the given active {@link Subscription} is for a paid plan.
 */
export const isSubscriptionActivePaid = (subscription: Subscription) =>
    subscription &&
    isSubscriptionActive(subscription) &&
    subscription.productID != "free";

/**
 * Return true if the given active {@link Subscription} is for a free plan.
 */
export const isSubscriptionActiveFree = (subscription: Subscription) =>
    subscription &&
    isSubscriptionActive(subscription) &&
    subscription.productID == "free";

/**
 * Return true if the given {@link Subscription} is using Stripe.
 */
export const isSubscriptionStripe = (subscription: Subscription) =>
    subscription && subscription.paymentProvider == "stripe";

/**
 * Return true if the given {@link Subscription} has the cancelled attribute.
 */
export const isSubscriptionCancelled = (subscription: Subscription) =>
    subscription && subscription.attributes?.isCancelled;

export function isSubscriptionPastDue(subscription: Subscription) {
    const thirtyDaysMicroseconds = 30 * 24 * 60 * 60 * 1000 * 1000;
    const currentTime = Date.now() * 1000;
    return (
        !isSubscriptionCancelled(subscription) &&
        subscription.expiryTime < currentTime &&
        subscription.expiryTime >= currentTime - thirtyDaysMicroseconds
    );
}

// Checks if the bonus data contain any bonus whose type starts with 'ADD_ON'
export function hasAddOnBonus(bonusData?: BonusData) {
    return (
        bonusData &&
        bonusData.storageBonuses &&
        bonusData.storageBonuses.length > 0 &&
        bonusData.storageBonuses.some((bonus) =>
            bonus.type.startsWith("ADD_ON"),
        )
    );
}

export function hasExceededStorageQuota(userDetails: UserDetails) {
    const bonusStorage = userDetails.storageBonus ?? 0;
    if (userDetails.familyData && isPartOfFamily(userDetails.familyData)) {
        const usage = getTotalFamilyUsage(userDetails.familyData);
        return usage > userDetails.familyData.storage + bonusStorage;
    } else {
        return (
            userDetails.usage > userDetails.subscription.storage + bonusStorage
        );
    }
}
