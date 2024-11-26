import { decryptMetadataJSON_New, sharedCryptoWorker } from "@/base/crypto";
import { authenticatedRequestHeaders, ensureOk, HTTPError } from "@/base/http";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { ensureString } from "@/utils/ensure";
import { getActualKey } from "@ente/shared/user";
import { codeFromURIString, type Code } from "services/code";
import { z } from "zod";

export const getAuthCodes = async (): Promise<Code[]> => {
    const masterKey = await getActualKey();
    const authenticatorEntityKey = await getAuthenticatorEntityKey();
    if (!authenticatorEntityKey) {
        // The user might not have stored any codes yet from the mobile app.
        return [];
    }

    const cryptoWorker = await sharedCryptoWorker();
    const authenticatorKey = await cryptoWorker.decryptB64(
        authenticatorEntityKey.encryptedKey,
        authenticatorEntityKey.header,
        masterKey,
    );
    const authEntities = await authenticatorEntityDiff(authenticatorKey);
    const authCodes = authEntities.map((entity) => {
        try {
            return codeFromURIString(entity.id, ensureString(entity.data));
        } catch (e) {
            log.error(`Failed to parse codeID ${entity.id}`, e);
            return undefined;
        }
    });

    const filteredAuthCodes = authCodes.filter((f) => f !== undefined);
    filteredAuthCodes.sort((a, b) => {
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
    return filteredAuthCodes;
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
    isDeleted: z.boolean(),
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

    // Always fetch all data from server for now.
    const params = new URLSearchParams({
        sinceTime: "0",
        limit: "2500",
    });
    const url = await apiURL("/authenticator/entity/diff");
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    const diff = z
        .object({ diff: z.array(RemoteAuthenticatorEntityChange) })
        .parse(await res.json()).diff;
    return Promise.all(
        diff
            .filter((entity) => !entity.isDeleted)
            .map(async ({ id, encryptedData, header }) => ({
                id,
                data: await decrypt(encryptedData!, header!),
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
