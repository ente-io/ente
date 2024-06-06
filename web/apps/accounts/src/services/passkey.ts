import { isDevBuild } from "@/next/env";
import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { toB64URLSafeNoPadding } from "@ente/shared/crypto/internal/libsodium";
import HTTPService from "@ente/shared/network/HTTPService";
import { getEndpoint } from "@ente/shared/network/api";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import _sodium from "libsodium-wrappers";

const ENDPOINT = getEndpoint();

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

export const getPasskeyRegistrationOptions = async () => {
    try {
        const token = getToken();
        if (!token) return;
        const response = await HTTPService.get(
            `${ENDPOINT}/passkeys/registration/begin`,
            {},
            {
                "X-Auth-Token": token,
            },
        );
        return await response.data;
    } catch (e) {
        log.error("get passkey registration options failed", e);
        throw e;
    }
};

/**
 * Return `true` if the given {@link redirectURL} (obtained from the redirect
 * query parameter passed around during the passkey verification flow) is one of
 * the whitelisted URLs that we allow redirecting to on success.
 */
export const isWhitelistedRedirect = (redirectURL: URL) =>
    (isDevBuild && redirectURL.host.endsWith("localhost")) ||
    redirectURL.host.endsWith(".ente.io") ||
    redirectURL.host.endsWith(".ente.sh") ||
    redirectURL.protocol == "ente:" ||
    redirectURL.protocol == "enteauth:";

/**
 * Add a new passkey as the second factor to the user's account.
 *
 * @param name An arbitrary name that the user wishes to label this passkey with
 * (aka "friendly name").
 */
export const registerPasskey = async (name: string) => {
    const response: {
        options: {
            publicKey: PublicKeyCredentialCreationOptions;
        };
        sessionID: string;
    } = await getPasskeyRegistrationOptions();

    const options = response.options;

    // TODO-PK: The types don't match.
    options.publicKey.challenge = _sodium.from_base64(
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        options.publicKey.challenge,
    );
    options.publicKey.user.id = _sodium.from_base64(
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        options.publicKey.user.id,
    );

    // create new credential
    const credential = ensure(await navigator.credentials.create(options));

    await finishPasskeyRegistration(name, credential, response.sessionID);
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
