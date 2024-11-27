import { authenticatedPublicAlbumsRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import { z } from "zod";

/**
 * Verify with remote that the password (hash) entered by the user is the same
 * as the password that was set by the person who shared the album. If they
 * match, remote will provide us with another token that can be used to make API
 * calls for this password protected public album.
 *
 * See: [Note: Password token for public albums requests]
 *
 * @param passwordHash The hash of the password entered by the user.
 *
 * @param token The access token to make API requests for a particular public
 * album.
 *
 * @returns The password token ("accessTokenJWT").
 */
export const verifyPublicCollectionPassword = async (
    passwordHash: string,
    accessToken: string,
) => {
    const res = await fetch(
        await apiURL("/public-collection/verify-password"),
        {
            method: "POST",
            headers: authenticatedPublicAlbumsRequestHeaders({ accessToken }),
            body: JSON.stringify({ passHash: passwordHash }),
        },
    );
    ensureOk(res);
    return z.object({ jwtToken: z.string() }).parse(await res.json()).jwtToken;
};
