import { object, type InferType } from "yup";

const apiOrigin = import.meta.env.VITE_ENTE_ENDPOINT ?? "https://api.ente.io";

const userDetailsSchema = object({});

export type UserDetails = InferType<typeof userDetailsSchema>;

/** Fetch details of the user associated with the given {@link authToken}. */
export const getUserDetails = async (
    authToken: string,
): Promise<UserDetails> => {
    const url = `${apiOrigin}/users/details/v2`;
    const res = await fetch(url, {
        headers: {
            "X-Auth-Token": authToken,
        },
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    return await userDetailsSchema.validate(await res.json());
};
