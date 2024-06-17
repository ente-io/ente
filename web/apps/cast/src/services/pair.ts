import log from "@/next/log";
import { wait } from "@/utils/promise";
import {
    boxSealOpen,
    generateKeyPair,
} from "@ente/shared/crypto/internal/libsodium";
import castGateway from "@ente/shared/network/cast";

export interface Registration {
    /** A pairing code shown on the screen. A client can use this to connect. */
    pairingCode: string;
    /** The public part of the keypair we registered with the server. */
    publicKeyB64: string;
    /** The private part of the keypair we registered with the server. */
    privateKeyB64: string;
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
 * Phase 3 - {@link getCastData} in a setInterval.
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
 * In parallel, we start Phase 3, calling {@link getCastData} in a loop. Once we
 * get a response, we decrypt it to get the data we need to start the slideshow.
 */
export const register = async (): Promise<Registration> => {
    // Generate keypair.
    const { publicKey: publicKeyB64, privateKey: privateKeyB64 } =
        await generateKeyPair();

    // Register keypair with museum to get a pairing code.
    let pairingCode: string | undefined;
    // eslint has fixed this spurious warning, but we're not on the latest
    // version yet, so add a disable.
    // https://github.com/eslint/eslint/pull/18286
    /* eslint-disable no-constant-condition */
    while (true) {
        try {
            pairingCode = await castGateway.registerDevice(publicKeyB64);
        } catch (e) {
            log.error("Failed to register public key with server", e);
        }
        if (pairingCode) break;
        // Schedule retry after 10 seconds.
        await wait(10000);
    }

    return { pairingCode, publicKeyB64, privateKeyB64 };
};

/**
 * Ask museum if anyone has sent a (encrypted) payload corresponding to the
 * given pairing code. If so, decrypt it using our private key and return the
 * JSON payload. Phase 3 of the pairing protocol.
 *
 * Returns `undefined` if there hasn't been any data obtained yet.
 *
 * See: [Note: Pairing protocol].
 */
export const getCastData = async (registration: Registration) => {
    const { pairingCode, publicKeyB64, privateKeyB64 } = registration;

    // The client will send us the encrypted payload using our public key that
    // we registered with museum.
    const encryptedCastData = await castGateway.getCastData(pairingCode);
    if (!encryptedCastData) return;

    // Decrypt it using the private key of the pair and return the plaintext
    // payload, which'll be a JSON object containing the data we need to start a
    // slideshow for some collection.
    const decryptedCastData = await boxSealOpen(
        encryptedCastData,
        publicKeyB64,
        privateKeyB64,
    );

    return JSON.parse(atob(decryptedCastData));
};
