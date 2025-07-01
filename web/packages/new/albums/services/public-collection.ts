import { deriveKey } from "ente-base/crypto";
import {
    authenticatedPublicAlbumsRequestHeaders,
    ensureOk,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import type { PublicURL } from "ente-media/collection";
import { z } from "zod/v4";

/**
 * Verify with remote that the password entered by the user is the same as the
 * password that was set by the person who shared the public album.
 *
 * The verification is done on a password hash that we check with remote. If
 * they match, remote will provide us with another token that can be used to
 * make API calls for this password protected public album.
 *
 * If they don't match, or if {@link accessToken} itself has expired, then
 * remote will return a HTTP 401.
 *
 * @param publicURL Data about the public album.
 *
 * @param password The password entered by the user.
 *
 * @param token The access token to make API requests for a particular public
 * album.
 *
 * @returns A accessTokenJWT.
 *
 * See [Note: Password token for public albums requests]
 */
export const verifyPublicAlbumPassword = async (
    publicURL: PublicURL,
    password: string,
    accessToken: string,
) => {
    const passwordHash = await deriveKey(
        password,
        // TODO: Fix the types to not require the bang.
        publicURL.nonce!,
        publicURL.opsLimit!,
        publicURL.memLimit!,
    );

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
