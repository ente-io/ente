import { boxSealOpenBytes, generateKeyPair } from "ente-base/crypto";
import { ensureOk, publicRequestHeaders } from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { wait } from "ente-utils/promise";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";

export interface Registration {
    /** A pairing code shown on the screen. A client can use this to connect. */
    pairingCode: string;
    /**
     * A base64 string representation of the public part of the keypair we
     * registered with the server.
     */
    publicKey: string;
    /**
     * A base64 string representation of the private part of the keypair we
     * registered with the server.
     */
    privateKey: string;
}

/**
 * Register a keypair with the server and return a pairing code that can be used
 * to connect to us. Phase 1 of the pairing protocol.
 *
 * [Note: Pairing protocol]
 *
 * The Chromecast Framework (represented here by our handle to the Chromecast
 * Web SDK, {@link cast}) itself is used for only the initial handshake, none of
 * the data, even encrypted passes over it thereafter.
 *
 * The pairing happens in two phases:
 *
 * Phase 1 - {@link register}
 *
 * 1. We (the receiver) generate a public/private keypair. and register the
 *    public part of it with museum.
 *
 * 2. Museum gives us a pairing "code" in lieu. Show this on the screen.
 *
 * Phase 2 - {@link advertiseCode}
 *
 * There are two ways the client can connect - either by sending us a blank
 * message over the Chromecast protocol (to which we'll reply with the pairing
 * code), or by the user manually entering the pairing code on their screen.
 *
 * 3. Listen for incoming messages over the Chromecast connection.
 *
 * 4. The client (our Web or mobile app) will connect using the "sender"
 *    Chromecast SDK. This will result in a bi-directional channel between us
 *    ("receiver") and the Ente client app ("sender").
 *
 * 5. Thereafter, if at any time the sender disconnects, close the Chromecast
 *    context. This effectively shuts us down, causing the entire page to get
 *    reloaded.
 *
 * 6. After connecting, the sender sends an (empty) message. We reply by sending
 *    them a message containing the pairing code. This exchange is the only data
 *    that traverses over the Chromecast connection.
 *
 * Once the client gets the pairing code (via Chromecast or manual entry),
 * they'll let museum know. So in parallel with Phase 2, we perform Phase 3.
 *
 * Phase 3 - {@link getCastPayload} in a setInterval.
 *
 * 7. Keep polling museum to ask it if anyone has claimed that code we vended
 *    out and used that to send us an payload encrypted using our public key.
 *
 * 8. When that happens, decrypt that data with our private key, and return this
 *    payload. It is a JSON object that contains the data we need to initiate a
 *    slideshow for a particular Ente collection.
 *
 * Phase 1 (Steps 1 and 2) are done by the {@link register} function, which
 * returns a {@link Registration}.
 *
 * At this time we start showing the pairing code on the UI, and start phase 2,
 * {@link advertiseCode} to vend out the pairing code to Chromecast connections.
 *
 * In parallel, we start Phase 3, calling {@link getCastPayload} in a loop. Once we
 * get a response, we decrypt it to get the data we need to start the slideshow.
 */
export const register = async (): Promise<Registration> => {
    // Generate keypair.
    const { publicKey, privateKey } = await generateKeyPair();

    // Register keypair with museum to get a pairing code.
    let pairingCode: string | undefined;
    while (true) {
        try {
            pairingCode = await registerDevice(publicKey);
        } catch (e) {
            log.error("Failed to register public key with server", e);
        }
        if (pairingCode) break;
        // Schedule retry after 10 seconds.
        await wait(10000);
    }

    return { pairingCode, publicKey, privateKey };
};

/**
 * Register the given {@link publicKey} with remote.
 *
 * @returns A device code that can be used to pair with us.
 */
const registerDevice = async (publicKey: string) => {
    const res = await fetch(await apiURL("/cast/device-info"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify({ publicKey }),
    });
    ensureOk(res);
    return z.object({ deviceCode: z.string() }).parse(await res.json())
        .deviceCode;
};

/**
 * The structure of the (decrypted) payload that is published (e.g.) by
 * `publishCastPayload` on the photos web/desktop app.
 */
const CastPayload = z.object({
    castToken: z.string(),
    collectionID: z.number(),
    collectionKey: z.string(),
});

export type CastPayload = z.infer<typeof CastPayload>;

/**
 * Ask museum if anyone has sent a (encrypted) payload corresponding to the
 * given pairing code. If so, decrypt it using our private key and return the
 * JSON payload. Phase 3 of the pairing protocol.
 *
 * Returns `undefined` if there hasn't been any data obtained yet.
 *
 * See: [Note: Pairing protocol].
 */
export const getCastPayload = async (
    registration: Registration,
): Promise<CastPayload | undefined> => {
    const { pairingCode, publicKey, privateKey } = registration;

    // The client will send us the encrypted payload using our public key that
    // we registered with museum.
    const encryptedCastData = await getEncryptedCastData(pairingCode);
    if (!encryptedCastData) return undefined;

    // Decrypt it using the private key of the pair and return the plaintext
    // payload, which'll be a JSON object containing the data we need to start a
    // slideshow for some collection.
    const jsonString = new TextDecoder().decode(
        await boxSealOpenBytes(encryptedCastData, { publicKey, privateKey }),
    );
    return CastPayload.parse(JSON.parse(jsonString));
};

/**
 * Fetch encrypted cast data corresponding to the given {@link code} from remote
 * if a client has already paired using it.
 */
const getEncryptedCastData = async (code: string) => {
    const res = await fetch(await apiURL(`/cast/cast-data/${code}`), {
        headers: publicRequestHeaders(),
    });
    ensureOk(res);
    return z
        .object({
            // encCastData will be null if pairing hasn't happened yet for the
            // given code.
            encCastData: z.string().nullish().transform(nullToUndefined),
        })
        .parse(await res.json()).encCastData;
};
