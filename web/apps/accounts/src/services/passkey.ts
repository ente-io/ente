import { isDevBuild } from "@/next/env";
import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { nullToUndefined } from "@/utils/transform";
import {
    fromB64URLSafeNoPadding,
    toB64URLSafeNoPadding,
} from "@ente/shared/crypto/internal/libsodium";
import HTTPService from "@ente/shared/network/HTTPService";
import { apiOrigin, getEndpoint } from "@ente/shared/network/api";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { z } from "zod";

const ENDPOINT = getEndpoint();

/**
 * Variant of {@link authenticatedRequestHeaders} but for authenticated requests
 * made by the accounts app.
 *
 * We cannot use {@link authenticatedRequestHeaders} directly because the
 * accounts app does not save a full user and instead only saves the user's
 * token (and that token too is scoped to the accounts APIs).
 */
const accountsAuthenticatedRequestHeaders = (): Record<string, string> => {
    const token = getToken();
    if (!token) throw new Error("Missing accounts token");
    const headers: Record<string, string> = { "X-Auth-Token": token };
    const clientPackage = nullToUndefined(
        localStorage.getItem("clientPackage"),
    );
    if (clientPackage) headers["X-Client-Package"] = clientPackage;
    return headers;
};

const Passkey = z.object({
    /** A unique ID for the passkey */
    id: z.string(),
    /**
     * An arbitrary name associated by the user with the passkey (a.k.a
     * its "friendly name").
     */
    friendlyName: z.string(),
    /**
     * Epoch milliseconds when this passkey was created.
     */
    createdAt: z.number(),
});

export type Passkey = z.infer<typeof Passkey>;

const GetPasskeysResponse = z.object({
    passkeys: z.array(Passkey),
});

/**
 * Fetch the existing passkeys for the user.
 *
 * @returns An array of {@link Passkey}s. The array will be empty if the user
 * has no passkeys.
 */
export const getPasskeys = async () => {
    const url = `${apiOrigin()}/passkeys`;
    const res = await fetch(url, {
        headers: accountsAuthenticatedRequestHeaders(),
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const { passkeys } = GetPasskeysResponse.parse(await res.json());
    return passkeys;
};

/**
 * Rename one of the user's existing passkey with the given {@link id}.
 *
 * @param id The `id` of the existing passkey to rename.
 *
 * @param name The new name (a.k.a. "friendly name").
 */
export const renamePasskey = async (id: string, name: string) => {
    const params = new URLSearchParams({ friendlyName: name });
    const url = `${apiOrigin()}/passkeys/${id}`;
    const res = await fetch(`${url}?${params.toString()}`, {
        method: "PATCH",
        headers: accountsAuthenticatedRequestHeaders(),
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
};

/**
 * Delete one of the user's existing passkeys.
 *
 * @param id The `id` of the existing passkey to delete.
 */
export const deletePasskey = async (id: string) => {
    const url = `${apiOrigin()}/passkeys/${id}`;
    const res = await fetch(url, {
        method: "DELETE",
        headers: accountsAuthenticatedRequestHeaders(),
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
};

/**
 * Add a new passkey as the second factor to the user's account.
 *
 * @param name An arbitrary name that the user wishes to label this passkey with
 * (a.k.a. "friendly name").
 */
export const registerPasskey = async (name: string) => {
    // Get options (and sessionID) from the backend.
    const { sessionID, options } = await beginPasskeyRegistration();

    // Ask the browser to new (public key) credentials using these options.
    const credential = ensure(await navigator.credentials.create(options));

    // Finish by letting the backend know about these credentials so that it can
    // save the public key for future authentication.
    await finishPasskeyRegistration(name, sessionID, credential);
};

interface BeginPasskeyRegistrationResponse {
    /**
     * An identifier for this registration ceremony / session.
     *
     * This sessionID is subsequently passed to the API when finish credential
     * creation to tie things together.
     */
    sessionID: string;
    /**
     * Options that should be passed to `navigator.credential.create` when
     * creating the new {@link Credential}.
     */
    options: {
        publicKey: PublicKeyCredentialCreationOptions;
    };
}

const beginPasskeyRegistration = async () => {
    const url = `${apiOrigin()}/passkeys/registration/begin`;
    const res = await fetch(url, {
        headers: accountsAuthenticatedRequestHeaders(),
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);

    // [Note: Converting binary data in WebAuthn API payloads]
    //
    // The server returns a JSON containing a "sessionID" (to tie together the
    // beginning and the end of the registration), and "options" that we should
    // pass on to the browser when asking it to create credentials.
    //
    // However, some massaging needs to be done first. On the backend, we use
    // the [go-webauthn](https://github.com/go-webauthn/webauthn) library to
    // begin the registration ceremony, and we verbatim credential creation
    // options that the library returns to us. These are meant to plug directly
    // into `CredentialCreationOptions` that `navigator.credential.create`
    // expects. Specifically, since we're creating a public key credential, the
    // `publicKey` attribute of the returned options will be in the shape of the
    // `PublicKeyCredentialCreationOptions` expected by the browser). Except,
    // binary data.
    //
    // Binary data in the returned `PublicKeyCredentialCreationOptions` are
    // serialized as a "URLEncodedBase64", which is a URL-encoded Base64 string
    // without any padding. The library is following the WebAuthn recommendation
    // when it does this:
    //
    // > The term "Base64url Encoding refers" to the base64 encoding using the
    // > URL- and filename-safe character set defined in Section 5 of RFC4648,
    // > which all trailing '=' characters omitted (as permitted by Section 3.2)
    // >
    // > https://www.w3.org/TR/webauthn-3/#base64url-encoding
    //
    // However, the browser expects binary data as an "ArrayBuffer, TypedArray
    // or DataView".
    // https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions
    //
    // So we do the conversion here.
    //
    // 1.  To avoid inventing an intermediary type and the boilerplate that'd
    //     come with it, we do a force typecast the options in the response to
    //     one that has `PublicKeyCredentialCreationOptions`.
    //
    // 2.  Convert the two binary data fields that are expected to be in the
    //     response from URLEncodedBase64 strings to Uint8Arrays. There is a
    //     third possibility, excludedCredentials[].id, but that we don't
    //     currently use.
    //
    // The web.dev guide calls this out too:
    //
    // > ArrayBuffer values transferred from the server such as `challenge`,
    // > `user.id` and credential `id` for `excludeCredentials` need to be
    // > encoded on transmission. Don't forget to decode them on the frontend
    // > before passing to the WebAuthn API call. We recommend using Base64URL
    // > encode.
    // >
    // > https://web.dev/articles/passkey-registration
    //
    // So that's that. But to further complicate things, the libdom.ts typings
    // included with the current TypeScript version (5.4) indicate these binary
    // types as a:
    //
    //     type BufferSource = ArrayBufferView | ArrayBuffer
    //
    // However MDN documentation states that they can be TypedArrays (e.g.
    // Uint8Arrays), and using Uint8Arrays works in practice too. So another
    // force cast is needed.
    //
    // ----
    //
    // Finally, the same process needs to happen, in reverse, when we're sending
    // the browser's response to credential creation to our backend for storing
    // that credential (for future authentication). Binary fields need to be
    // converted to URL-safe B64 before transmission.

    const { sessionID, options } =
        (await res.json()) as BeginPasskeyRegistrationResponse;

    options.publicKey.challenge = await serverB64ToBinary(
        options.publicKey.challenge,
    );

    options.publicKey.user.id = await serverB64ToBinary(
        options.publicKey.user.id,
    );

    return { sessionID, options };
};

/**
 * This is the function that does the dirty work for the binary conversion,
 * including the unfortunate typecasts.
 *
 * See: [Note: Converting binary data in WebAuthn API payloads]
 */
const serverB64ToBinary = async (b: BufferSource) => {
    // This is actually a URL-safe B64 string without trailing padding.
    const b64String = b as unknown as string;
    // Convert it to a Uint8Array by doing the appropriate B64 decoding.
    const bytes = await fromB64URLSafeNoPadding(b64String);
    // Cast again to satisfy the incomplete BufferSource type.
    return bytes as unknown as BufferSource;
};

/**
 * This is the sibling of {@link serverB64ToBinary} that does the conversions in
 * the other direction.
 *
 * See: [Note: Converting binary data in WebAuthn API payloads]
 */
const binaryToServerB64 = async (b: ArrayBuffer) => {
    // Convert it to a Uint8Array
    const bytes = new Uint8Array(b);
    // Convert to a URL-safe B64 string without any trailing padding.
    const b64String = await toB64URLSafeNoPadding(bytes);
    // Lie about the types to make the compiler happy.
    return b64String as unknown as BufferSource;
};

const finishPasskeyRegistration = async (
    sessionID: string,
    friendlyName: string,
    credential: Credential,
) => {
    const attestationResponse = authenticatorAttestationResponse(credential);

    const attestationObject = await binaryToServerB64(
        attestationResponse.attestationObject,
    );
    const clientDataJSON = await binaryToServerB64(
        attestationResponse.clientDataJSON,
    );

    const params = new URLSearchParams({ friendlyName, sessionID });
    const url = `${apiOrigin()}/passkeys/registration/finish`;
    const res = await fetch(`${url}?${params.toString()}`, {
        method: "POST",
        headers: accountsAuthenticatedRequestHeaders(),
        body: JSON.stringify({
            id: credential.id,
            // This is meant to be the ArrayBuffer version of the (base64
            // encoded) `id`, but since we then would need to base64 encode it
            // anyways for transmission, we can just reuse the same string.
            rawId: credential.id,
            type: credential.type,
            response: {
                attestationObject,
                clientDataJSON,
            },
        }),
    });
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
};

/**
 * A function to hide the type casts necessary to extract an
 * {@link AuthenticatorAttestationResponse} from the {@link Credential} we
 * obtain during a new passkey registration.
 */
const authenticatorAttestationResponse = (credential: Credential) => {
    // We passed `options: { publicKey }` to `navigator.credentials.create`, and
    // so we will get back an `PublicKeyCredential`:
    // https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#creating_a_public_key_credential
    //
    // However, the return type of `create` is the base `Credential`, so we need
    // to cast.
    const pkCredential = credential as PublicKeyCredential;

    // Further, since this was a `create` and not a `get`, the
    // PublicKeyCredential.response will be an
    // `AuthenticatorAttestationResponse` (See same MDN reference).
    //
    // We need to cast again.
    const attestationResponse =
        pkCredential.response as AuthenticatorAttestationResponse;

    return attestationResponse;
};
/**
 * Return `true` if the given {@link redirectURL} (obtained from the redirect
 * query parameter passed around during the passkey verification flow) is one of
 * the whitelisted URLs that we allow redirecting to on success.
 */
export const isWhitelistedRedirect = (redirectURL: URL) =>
    (isDevBuild && redirectURL.hostname.endsWith("localhost")) ||
    redirectURL.host.endsWith(".ente.io") ||
    redirectURL.host.endsWith(".ente.sh") ||
    redirectURL.protocol == "ente:" ||
    redirectURL.protocol == "enteauth:";

export interface BeginPasskeyAuthenticationResponse {
    ceremonySessionID: string;
    options: Options;
}

interface Options {
    publicKey: PublicKeyCredentialRequestOptions;
}

export const beginPasskeyAuthentication = async (
    sessionId: string,
): Promise<BeginPasskeyAuthenticationResponse> => {
    try {
        const data = await HTTPService.post(
            `${ENDPOINT}/users/two-factor/passkeys/begin`,
            {
                sessionID: sessionId,
            },
        );

        return data.data;
    } catch (e) {
        log.error("begin passkey authentication failed", e);
        throw e;
    }
};

export const finishPasskeyAuthentication = async (
    credential: Credential,
    sessionId: string,
    ceremonySessionId: string,
) => {
    try {
        const data = await HTTPService.post(
            `${ENDPOINT}/users/two-factor/passkeys/finish`,
            {
                id: credential.id,
                rawId: credential.id,
                type: credential.type,
                response: {
                    authenticatorData: await toB64URLSafeNoPadding(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.authenticatorData),
                    ),
                    clientDataJSON: await toB64URLSafeNoPadding(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.clientDataJSON),
                    ),
                    signature: await toB64URLSafeNoPadding(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.signature),
                    ),
                    userHandle: await toB64URLSafeNoPadding(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.userHandle),
                    ),
                },
            },
            {
                sessionID: sessionId,
                ceremonySessionID: ceremonySessionId,
            },
        );

        return data.data;
    } catch (e) {
        log.error("finish passkey authentication failed", e);
        throw e;
    }
};
