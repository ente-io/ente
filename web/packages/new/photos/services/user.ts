import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { getKV, setKV } from "@/base/kv";
import { apiURL } from "@/base/origins";
import { getData, LS_KEYS, setLSUser } from "@ente/shared/storage/localStorage";
import { z } from "zod";
import { FamilyData } from "./family";
import { Subscription } from "./plan";

const BonusData = z.object({
    /**
     * List of bonuses applied for the user.
     */
    storageBonuses: z
        .object({
            type: z.string() /** The type of the bonus. */,
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
     * Subscriptions to {@link UserDetails} updates attached using
     * {@link userDetailsSubscribe}.
     */
    userDetailsListeners: (() => void)[] = [];

    /**
     * Snapshot of the {@link UserDetails} returned by the
     * {@link userDetailsSnapshot} function.
     */
    userDetailsSnapshot: UserDetails | undefined;
}

/** State shared by the functions in this module. See {@link UserState}. */
let _state = new UserState();

export const logoutUserDetails = () => {
    _state = new UserState();
};

/**
 * Read in the locally persisted settings into memory, but otherwise do not
 * initate any network requests to fetch the latest values.
 *
 * This assumes that the user is already logged in.
 */
export const initUserDetails = async () => {
    const saved = await getKV("userDetails");
    if (saved) setUserDetailsSnapshot(UserDetails.parse(saved));
};

/**
 * A function that can be used to subscribe to updates to {@link UserDetails}.
 *
 * [Note: Snapshots and useSyncExternalStore]
 *
 * This subscribe function, along with {@link userDetailsSnapshot}, is meant to
 * be used as arguments to React's {@link useSyncExternalStore}.
 *
 * @param callback A function that will be invoked whenever the result of
 * {@link userDetailsSnapshot} changes.
 *
 * @returns A function that can be used to clear the subscription.
 */
export const userDetailsSubscribe = (onChange: () => void): (() => void) => {
    _state.userDetailsListeners.push(onChange);
    return () => {
        _state.userDetailsListeners = _state.userDetailsListeners.filter(
            (l) => l != onChange,
        );
    };
};

/**
 * Return the last known, cached {@link UserDetails}.
 *
 * This, along with {@link userDetailsSubscribe}, is meant to be used as
 * arguments to React's {@link useSyncExternalStore}.
 */
export const userDetailsSnapshot = () => _state.userDetailsSnapshot;

const setUserDetailsSnapshot = (snapshot: UserDetails) => {
    _state.userDetailsSnapshot = snapshot;
    _state.userDetailsListeners.forEach((l) => l());
};

/**
 * Fetch the user's details from remote and save them in local storage for
 * subsequent lookup, and also update our in-memory snapshots.
 */
export const syncUserDetails = async () => {
    const userDetails = await getUserDetailsV2();
    await setKV("userDetails", userDetails);
    setUserDetailsSnapshot(userDetails);

    // TODO: The existing code used to also set the email for the local storage
    // user whenever it updated the user details. I don't see why this would be
    // needed though.
    //
    // Retaining the existing behaviour for now, except we throw. The intent is
    // to remove this entire copy-over after a bit.
    //
    // Added Nov 2024, and can be removed after a while (tag: Migration).

    const oldLSUser = getData(LS_KEYS.USER) as unknown;
    const hasMatchingEmail =
        oldLSUser &&
        typeof oldLSUser == "object" &&
        "email" in oldLSUser &&
        typeof oldLSUser.email == "string" &&
        oldLSUser.email == userDetails.email;

    if (!hasMatchingEmail) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        await setLSUser({
            ...getData(LS_KEYS.USER),
            email: userDetails.email,
        });
        throw new Error("Email in local storage did not match user details");
    }
};

/**
 * Fetch user details from remote.
 */
export const getUserDetailsV2 = async () => {
    const res = await fetch(await apiURL("/users/details/v2"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return UserDetails.parse(await res.json());
};

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
