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

export interface Passkey {
    id: string;
    userID: number;
    friendlyName: string;
    createdAt: number;
}

export const getPasskeys = async () => {
    const token = getToken();
    if (!token) return;
    const response = await HTTPService.get(
        `${ENDPOINT}/passkeys`,
        {},
        { "X-Auth-Token": token },
    );
    return await response.data;
};

export const renamePasskey = async (id: string, name: string) => {
    try {
        const token = getToken();
        if (!token) return;
        const response = await HTTPService.patch(
            `${ENDPOINT}/passkeys/${id}`,
            {},
            { friendlyName: name },
            { "X-Auth-Token": token },
        );
        return await response.data;
    } catch (e) {
        log.error("rename passkey failed", e);
        throw e;
    }
};

export const deletePasskey = async (id: string) => {
    try {
        const token = getToken();
        if (!token) return;
        const response = await HTTPService.delete(
            `${ENDPOINT}/passkeys/${id}`,
            {},
            {},
            { "X-Auth-Token": token },
        );
        return await response.data;
    } catch (e) {
        log.error("delete passkey failed", e);
        throw e;
    }
};

/**
 * Add a new passkey as the second factor to the user's account.
 *
 * @param name An arbitrary name that the user wishes to label this passkey with
 * (aka "friendly name").
 */
export const registerPasskey = async (name: string) => {
    // Get options (and sessionID) from the backend.
    const { sessionID, options } = await beginPasskeyRegistration();

    // Ask the browser to new (public key) credentials using these options.
    const credential = ensure(await navigator.credentials.create(options));

    // Finish by letting the backend know about these credentials so that it can
    // save the public key for future authentication.
    await finishPasskeyRegistration(name, credential, sessionID);
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

const finishPasskeyRegistration = async (
    friendlyName: string,
    credential: Credential,
    sessionID: string,
) => {
    const attestationObjectB64 = await toB64URLSafeNoPadding(
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        new Uint8Array(credential.response.attestationObject),
    );
    const clientDataJSONB64 = await toB64URLSafeNoPadding(
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        new Uint8Array(credential.response.clientDataJSON),
    );

    const token = ensure(getToken());

    const response = await HTTPService.post(
        `${ENDPOINT}/passkeys/registration/finish`,
        JSON.stringify({
            id: credential.id,
            rawId: credential.id,
            type: credential.type,
            response: {
                attestationObject: attestationObjectB64,
                clientDataJSON: clientDataJSONB64,
            },
        }),
        {
            friendlyName,
            sessionID,
        },
        {
            "X-Auth-Token": token,
        },
    );
    return await response.data;
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
