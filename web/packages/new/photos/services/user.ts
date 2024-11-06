import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import { z } from "zod";
import type { FamilyData } from "./family";
import type { Subscription } from "./plan";

export interface Bonus {
    storage: number;
    type: string;
    validTill: number;
    isRevoked: boolean;
}

export interface BonusData {
    storageBonuses: Bonus[];
}

export interface UserDetails {
    email: string;
    usage: number;
    fileCount: number;
    sharedCollectionCount: number;
    subscription: Subscription;
    familyData?: FamilyData;
    storageBonus?: number;
    bonusData?: BonusData;
}

/**
 * Fetch the two-factor status (whether or not it is enabled) from remote.
 */
export const get2FAStatus = async () => {
    const res = await fetch(await apiURL("/users/two-factor/status"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return z.object({ status: z.boolean() }).parse(await res.json()).status;
};

/**
 * Disable two-factor authentication for the current user on remote.
 */
export const disable2FA = async () =>
    ensureOk(
        await fetch(await apiURL("/users/two-factor/disable"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        }),
    );
