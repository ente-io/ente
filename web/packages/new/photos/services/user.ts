import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import { z } from "zod";
import { FamilyData } from "./family";
import { Subscription } from "./plan";

const BonusData = z.object({
    /**
     * List of bonuses applied for the user.
     */
    storageBonuses: z
        .object({
            /**
             * The type of the bonus.
             */
            type: z.string(),
        })
        .array(),
});

/**
 * Information about bonuses applied to the user.
 */
export type BonusData = z.infer<typeof BonusData>;

/**
 * Zod schema for {@link UserDetails}
 */
const UserDetails = z.object({
    email: z.string(),
    usage: z.number(),
    fileCount: z.number().optional(),
    subscription: Subscription,
    familyData: FamilyData.optional(),
    storageBonus: z.number().optional(),
    bonusData: BonusData.optional(),
});

export type UserDetails = z.infer<typeof UserDetails>;

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class UserState {
    /**
     * Subscriptions to {@link UserDetails} updates.
     *
     * See {@link userDetailsSubscribe}.
     */
    userDetailsListeners: (() => void)[] = [];

    /**
     * Snapshot of the {@link UserDetails} returned by the
     * {@link userDetailsSnapshot} function.
     */
    userDetailsSnapshot: UserDetails | undefined;
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
