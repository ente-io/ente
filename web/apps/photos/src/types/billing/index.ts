import { PLAN_PERIOD } from "constants/gallery";

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
    period: PLAN_PERIOD;
}
export interface Plan {
    id: string;
    androidID: string;
    iosID: string;
    storage: number;
    price: string;
    period: PLAN_PERIOD;
    stripeID: string;
}
