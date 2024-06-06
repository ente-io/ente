// TODO: This file belongs to the accounts package
import { z } from "zod";

const LocalUser = z.object({
    /** The user's ID. */
    id: z.number(),
    /** The user's email. */
    email: z.string(),
    /**
     * The user's (plaintext) auth token.
     *
     * It is used for making API calls on their behalf.
     */
    token: z.string(),
});

/** Locally available data for the logged in user */
export type LocalUser = z.infer<typeof LocalUser>;

/**
 * Return the logged-in user, if someone is indeed logged in. Otherwise return
 * `undefined`.
 *
 * The user's data is stored in the browser's localStorage.
 */
export const localUser = (): LocalUser | undefined => {
    // TODO(MR): duplicate of LS_KEYS.USER
    const s = localStorage.getItem("user");
    if (!s) return undefined;
    return LocalUser.parse(JSON.parse(s));
};

/**
 * A wrapper over {@link localUser} with that throws if no one is logged in.
 */
export const ensureLocalUser = (): LocalUser => {
    const user = localUser();
    if (!user) throw new Error("Not logged in");
    return user;
};
