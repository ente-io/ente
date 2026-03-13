import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { z } from "zod";

/**
 * Zod schema for an individual session returned by the API.
 */
const Session = z.object({
    /**
     * The session token.
     */
    token: z.string(),
    /**
     * The time (epoch microseconds) when the session was created.
     */
    creationTime: z.number(),
    /**
     * The IP address from which the session was created.
     */
    ip: z.string(),
    /**
     * The raw user agent string.
     */
    ua: z.string(),
    /**
     * A human-readable version of the user agent.
     */
    prettyUA: z.string(),
    /**
     * The time (epoch microseconds) when the session was last used.
     */
    lastUsedTime: z.number(),
});

/**
 * TypeScript type for a session, derived from the Zod schema.
 */
export type Session = z.infer<typeof Session>;

/**
 * Zod schema for the sessions API response.
 */
const SessionsResponse = z.object({ sessions: z.array(Session) });

/**
 * Fetch all active sessions for the current user.
 *
 * @returns A promise that resolves to an array of {@link Session} objects,
 * sorted by last used time (most recent first).
 */
export const getActiveSessions = async (): Promise<Session[]> => {
    const res = await fetch(await apiURL("/users/sessions"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const { sessions } = SessionsResponse.parse(await res.json());
    // Sort by last used time, most recent first.
    return sessions.sort((a, b) => b.lastUsedTime - a.lastUsedTime);
};

/**
 * Terminate a specific session.
 *
 * @param token The token of the session to terminate.
 */
export const terminateSession = async (token: string): Promise<void> => {
    const url = await apiURL("/users/session");
    const res = await fetch(`${url}?token=${encodeURIComponent(token)}`, {
        method: "DELETE",
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
};
