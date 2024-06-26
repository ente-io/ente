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
     * It is used for making API calls on their behalf, by passing this token as
     * the value of the X-Auth-Token header in the HTTP request.
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

/**
 * Return the user's auth token, or throw an error.
 *
 * The user's auth token is stored in local storage after they have successfully
 * logged in. This function returns that saved auth token.
 *
 * If no such token is found (which should only happen if the user is not logged
 * in), then it throws an error.
 */
export const ensureAuthToken = (): string => ensureLocalUser().token;
