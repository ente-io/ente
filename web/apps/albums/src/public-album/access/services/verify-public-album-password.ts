import { deriveKey } from "ente-base/crypto";
import {
    authenticatedPublicAlbumsRequestHeaders,
    ensureOk,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import type { PublicURL } from "ente-media/collection";
import { z } from "zod";

/**
 * Verify the password entered for a password-protected public album and return
 * the JWT token needed for subsequent authenticated public-album requests.
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
