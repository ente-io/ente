import { boxSeal } from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { newID } from "ente-base/id";
import { apiURL } from "ente-base/origins";
import type { Collection } from "ente-media/collection";
import { z } from "zod/v4";

/**
 * Revoke all existing outstanding cast tokens for the current user on remote.
 */
export const revokeAllCastTokens = async () =>
    ensureOk(
        await fetch(await apiURL("/cast/revoke-all-tokens"), {
            method: "DELETE",
            headers: await authenticatedRequestHeaders(),
        }),
    );

/**
 * Fetch the public key (represented as a base64 string) associated with the
 * given device / pairing {@link code} from remote, or `undefined` if there is
 * no public key associated with the given code.
 */
export const publicKeyForPairingCode = async (code: string) => {
    const res = await fetch(await apiURL(`/cast/device-info/${code}`), {
        headers: await authenticatedRequestHeaders(),
    });
    if (res.status == 404) return undefined;
    ensureOk(res);
    return z.object({ publicKey: z.string() }).parse(await res.json())
        .publicKey;
};

export const unknownDeviceCodeErrorMessage = "Unknown device code";

/**
 * Publish encrypted payload for a cast session so that the paired device can
 * obtain the information it needs to cast a collection.
 *
 * If no device was found for the given {@link deviceCode}, then this function
 * will throw an error with the message
 * @param deviceCode The PIN / device code that the user entered to pair with
 * the casting end.
 *
 * @param collection The collection that the user wants to cast.
 */
export const publishCastPayload = async (
    deviceCode: string,
    collection: Collection,
) => {
    // Find out the public key associated with the given pairing code (if
    // indeed a device has published one).
    const publicKey = await publicKeyForPairingCode(deviceCode);
    if (!publicKey) throw new Error(unknownDeviceCodeErrorMessage);

    // Generate random id.
    const castToken = newID("cast_");

    // Publish the payload so that the other end can use it.
    const payload = JSON.stringify({
        castToken,
        collectionID: collection.id,
        collectionKey: collection.key,
    });
    const encryptedPayload = await boxSeal(btoa(payload), publicKey);
    const res = await fetch(await apiURL("/cast/cast-data"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({
            castToken,
            deviceCode,
            encPayload: encryptedPayload,
            collectionID: collection.id,
        }),
    });
    ensureOk(res);
};
