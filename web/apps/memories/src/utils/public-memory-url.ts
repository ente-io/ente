import { toB64 } from "ente-base/crypto";
import { extractCollectionKeyFromShareURL } from "ente-gallery/services/share";

const shortMemorySecretPattern = /^[0-9A-Za-z]{12}$/;

export const extractMemoryShareKeyFromURL = async (
    url: URL,
): Promise<string | null> => {
    const fragment = url.hash.slice(1).trim();
    if (!fragment) return null;

    if (shortMemorySecretPattern.test(fragment)) {
        const digest = await globalThis.crypto.subtle.digest(
            "SHA-256",
            new TextEncoder().encode(fragment),
        );
        return await toB64(new Uint8Array(digest));
    }

    return await extractCollectionKeyFromShareURL(url);
};

export const extractAccessTokenFromURL = (url: URL): string | null => {
    const tokenFromQuery =
        url.searchParams.get("t") ?? url.searchParams.get("accessToken");
    if (tokenFromQuery) {
        return tokenFromQuery;
    }

    // Support:
    // - /<TOKEN>#<SECRET>
    // - /memory/<TOKEN>#<SECRET>
    // - /memories/<TOKEN>#<SECRET>
    // while treating bare /memory and /memories as no-token landing routes.
    const routePrefixes = new Set(["memory", "memories"]);
    const pathSegments = url.pathname
        .split("/")
        .filter((segment) => segment.length > 0);
    for (let i = pathSegments.length - 1; i >= 0; i--) {
        const segment = pathSegments[i]!;
        if (!routePrefixes.has(segment.toLowerCase())) {
            return segment;
        }
    }

    return null;
};
