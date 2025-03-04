import { decryptBoxB64, decryptMetadataJSON_New } from "@/base/crypto";
import { authenticatedRequestHeaders, ensureOk, HTTPError } from "@/base/http";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { ensureString } from "@/utils/ensure";
import { codeFromURIString, type Code } from "services/code";
import { z } from "zod";

export const getAuthCodes = async (masterKey: Uint8Array): Promise<Code[]> => {
    const authenticatorEntityKey = await getAuthenticatorEntityKey();
    if (!authenticatorEntityKey) {
        // The user might not have stored any codes yet from the mobile app.
        return [];
    }

    const authenticatorKey = await decryptAuthenticatorKey(
        authenticatorEntityKey,
        masterKey,
    );
    return (await authenticatorEntityDiff(authenticatorKey))
        .map((entity) => {
            try {
                return codeFromURIString(entity.id, ensureString(entity.data));
            } catch (e) {
                log.error(`Failed to parse codeID ${entity.id}`, e);
                return undefined;
            }
        })
        .filter((f) => f !== undefined)
        .filter((f) => {
            // Do not show trashed entries in the web inteface.
            return !f.codeDisplay?.trashed;
        })
        .sort((a, b) => {
            // If only one of them is pinned, prefer it.
            if (a.codeDisplay?.pinned && !b.codeDisplay?.pinned) return -1;
            if (!a.codeDisplay?.pinned && b.codeDisplay?.pinned) return 1;
            // If we get here, either both are pinned, or none are...

            // Sort by issuer, alphabetically.
            if (a.issuer && b.issuer) {
                return a.issuer.localeCompare(b.issuer);
            }
            if (a.issuer) {
                return -1;
            }
            if (b.issuer) {
                return 1;
            }
            return 0;
        });
};

/**
 * Authenticator entities obtained from remote.
 */
interface AuthenticatorEntity {
    id: string;
    data: unknown;
}

/**
 * Zod schema for a item in the user entity diff.
 */
const RemoteAuthenticatorEntityChange = z.object({
    id: z.string(),
    /**
     * Base64 string containing the encrypted contents of the entity.
     *
     * Will be `null` when isDeleted is true.
     */
    encryptedData: z.string().nullable(),
    /**
     * Base64 string containing the decryption header.
     *
     * Will be `null` when isDeleted is true.
     */
    header: z.string().nullable(),
    /**
     * `true` if the corresponding entity was deleted.
     */
    isDeleted: z.boolean(),
    /**
     * Epoch microseconds when this entity was last updated.
     *
     * This value is suitable for being passed as the `sinceTime` in the diff
     * requests to implement pagination.
     */
    updatedAt: z.number(),
});

/**
 * Fetch all the authenticator entities for the user.
 *
 * @param authenticatorKey The (base64 encoded) key that should be used for
 * decrypting the authenticator entities received from remote.
 */
export const authenticatorEntityDiff = async (
    authenticatorKey: string,
): Promise<AuthenticatorEntity[]> => {
    const decrypt = (encryptedData: string, decryptionHeader: string) =>
        decryptMetadataJSON_New(
            { encryptedData, decryptionHeader },
            authenticatorKey,
        );

    // Fetch all the entities, paginating the requests.
    const entities = new Map<
        string,
        { id: string; encryptedData: string; header: string }
    >();
    let sinceTime = 0;
    const batchSize = 2500;

    while (true) {
        const params = new URLSearchParams({
            sinceTime: `${sinceTime}`,
            limit: `${batchSize}`,
        });
        const url = await apiURL("/authenticator/entity/diff");
        const res = await fetch(`${url}?${params.toString()}`, {
            headers: await authenticatedRequestHeaders(),
        });
        ensureOk(res);
        const diff = z
            .object({ diff: z.array(RemoteAuthenticatorEntityChange) })
            .parse(await res.json()).diff;
        if (diff.length == 0) break;

        for (const change of diff) {
            sinceTime = Math.max(sinceTime, change.updatedAt);
            if (change.isDeleted) {
                entities.delete(change.id);
            } else {
                entities.set(change.id, {
                    id: change.id,
                    encryptedData: change.encryptedData!,
                    header: change.header!,
                });
            }
        }
    }

    return Promise.all(
        [...entities.values()].map(async ({ id, encryptedData, header }) => ({
            id,
            data: await decrypt(encryptedData, header),
        })),
    );
};

export const AuthenticatorEntityKey = z.object({
    /**
     * The authenticator entity key (base 64 string), encrypted with the user's
     * master key.
     */
    encryptedKey: z.string(),
    /**
     * Base64 encoded nonce used during encryption of the authenticator key.
     */
    header: z.string(),
});

export type AuthenticatorEntityKey = z.infer<typeof AuthenticatorEntityKey>;

/**
 * Fetch the encryption key for the authenticator entities from remote.
 *
 * This is a special case of an entity key for use with "authenticator"
 * entities. See: [Note: User entity keys].
 *
 * @returns the authenticator key, or undefined if there is no authenticator key
 * yet created on remote for the user.
 */
export const getAuthenticatorEntityKey = async (): Promise<
    AuthenticatorEntityKey | undefined
> => {
    const res = await fetch(await apiURL("/authenticator/key"), {
        headers: await authenticatedRequestHeaders(),
    });
    if (!res.ok) {
        // Remote says HTTP 404 Not Found if there is no key yet for the user.
        if (res.status == 404) return undefined;
        throw new HTTPError(res);
    } else {
        return AuthenticatorEntityKey.parse(await res.json());
    }
};

/**
 * Decrypt an encrypted authenticator key using the user's master key.
 */
const decryptAuthenticatorKey = async (
    remote: AuthenticatorEntityKey,
    masterKey: Uint8Array,
) =>
    decryptBoxB64(
        {
            encryptedData: remote.encryptedKey,
            // Remote calls it the header, but it really is the nonce.
            nonce: remote.header,
        },
        masterKey,
    );
