import { z } from "zod";
import { getEmail, getToken } from "./session";

export const apiOrigin =
    import.meta.env.VITE_ENTE_API_ORIGIN ?? "https://api.ente.io";

const UserDetailsSchema = z.looseObject({});

export type UserDetails = z.infer<typeof UserDetailsSchema>;

/** Fetch details of the user associated with the given {@link authToken}. */
export const getUserDetails = async (
    authToken: string,
): Promise<UserDetails> => {
    const url = `${apiOrigin}/users/details/v2`;
    const res = await fetch(url, { headers: { "X-Auth-Token": authToken } });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    return UserDetailsSchema.parse(await res.json());
};

const requireEmail = () => {
    const email = getEmail();
    if (!email) throw new Error("Email not found");
    return email;
};

export const requireToken = () => {
    const token = getToken();
    if (!token) throw new Error("Token not found");
    return token;
};

export const responseErrorMessage = async (
    response: Response,
    fallback: string,
) => {
    const text = await response.text();
    if (!text) {
        return fallback;
    }

    try {
        const body = JSON.parse(text) as unknown;
        if (body && typeof body === "object" && "message" in body) {
            const { message } = body as { message?: unknown };
            if (typeof message === "string" && message) {
                return message;
            }
        }
    } catch {
        return text;
    }

    return text;
};

export const getCurrentAdminUser = async <T>(): Promise<T> => {
    const email = requireEmail();
    const token = requireToken();
    const url = `${apiOrigin}/admin/user?email=${encodeURIComponent(email)}`;
    const response = await fetch(url, {
        headers: { "Content-Type": "application/json", "X-Auth-Token": token },
    });
    if (!response.ok) {
        throw new Error(
            await responseErrorMessage(response, "Failed to fetch user data"),
        );
    }
    return (await response.json()) as T;
};

export const getCurrentAdminUserId = async () => {
    const userData = await getCurrentAdminUser<{
        subscription?: { userID?: string } | null;
    }>();
    const userId = userData.subscription?.userID;
    if (!userId) throw new Error("User ID not found");
    return userId;
};
