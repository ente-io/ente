import { z } from "zod";

export const apiOrigin =
    import.meta.env.VITE_ENTE_API_ORIGIN ?? "https://api.ente.io";

const UserDetails = z.object({}).passthrough();

export type UserDetails = z.infer<typeof UserDetails>;

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
    return UserDetails.parse(await res.json());
};
