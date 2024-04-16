// TODO: This file belongs to the accounts package
import * as yup from "yup";

const localUserSchema = yup.object({
    /** The user's ID. */
    id: yup.number().required(),
    /** The user's email. */
    email: yup.string().required(),
    /**
     * The user's (plaintext) auth token.
     *
     * It is used for making API calls on their behalf.
     */
    token: yup.string().required(),
});

/** Locally available data for the logged in user's */
export type LocalUser = yup.InferType<typeof localUserSchema>;

/**
 * Return the logged-in user (if someone is indeed logged in).
 *
 * The user's data is stored in the browser's localStorage.
 */
export const localUser = async (): Promise<LocalUser | undefined> => {
    // TODO(MR): duplicate of LS_KEYS.USER
    const s = localStorage.getItem("user");
    if (!s) return undefined;
    return await localUserSchema.validate(JSON.parse(s), {
        strict: true,
    });
};

/**
 * A wrapper over {@link localUser} with that throws if no one is logged in.
 */
export const ensureLocalUser = async (): Promise<LocalUser> => {
    const user = await localUser();
    if (!user)
        throw new Error("Attempting to access user data when not logged in");
    return user;
};
