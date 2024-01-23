import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint } from '@ente/shared/network/api';
import { logError } from '@ente/shared/sentry';
import { getToken } from '@ente/shared/storage/localStorage/helpers';
import _sodium from 'libsodium-wrappers';
const ENDPOINT = getEndpoint();

export const getPasskeys = async () => {
    try {
        const token = getToken();
        if (!token) return;
        const response = await HTTPService.get(
            `${ENDPOINT}/passkeys`,
            {},
            { 'X-Auth-Token': token }
        );
        return await response.data;
    } catch (e) {
        logError(e, 'get passkeys failed');
        throw e;
    }
};

export const renamePasskey = async (id: string, name: string) => {
    try {
        const token = getToken();
        if (!token) return;
        const response = await HTTPService.patch(
            `${ENDPOINT}/passkeys/${id}`,
            {},
            { friendlyName: name },
            { 'X-Auth-Token': token }
        );
        return await response.data;
    } catch (e) {
        logError(e, 'rename passkey failed');
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
            { 'X-Auth-Token': token }
        );
        return await response.data;
    } catch (e) {
        logError(e, 'delete passkey failed');
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
                'X-Auth-Token': token,
            }
        );
        return await response.data;
    } catch (e) {
        logError(e, 'get passkey registration options failed');
        throw e;
    }
};

export const finishPasskeyRegistration = async (
    friendlyName: string,
    credential: Credential,
    sessionId: string
) => {
    try {
        const attestationObjectB64 = _sodium.to_base64(
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            new Uint8Array(credential.response.attestationObject),
            _sodium.base64_variants.URLSAFE_NO_PADDING
        );
        const clientDataJSONB64 = _sodium.to_base64(
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            new Uint8Array(credential.response.clientDataJSON),
            _sodium.base64_variants.URLSAFE_NO_PADDING
        );

        const token = getToken();
        if (!token) return;

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
                sessionID: sessionId,
            },
            {
                'X-Auth-Token': token,
            }
        );
        return await response.data;
    } catch (e) {
        logError(e, 'finish passkey registration failed');
        throw e;
    }
};

export interface BeginPasskeyAuthenticationResponse {
    ceremonySessionID: string;
    options: Options;
}
interface Options {
    publicKey: PublicKeyCredentialRequestOptions;
}

export const beginPasskeyAuthentication = async (
    sessionId: string
): Promise<BeginPasskeyAuthenticationResponse> => {
    try {
        const data = await HTTPService.post(
            `${ENDPOINT}/users/two-factor/passkeys/begin`,
            {
                sessionID: sessionId,
            }
        );

        return data.data;
    } catch (e) {
        logError(e, 'begin passkey authentication failed');
        throw e;
    }
};

export const finishPasskeyAuthentication = async (
    credential: Credential,
    sessionId: string,
    ceremonySessionId: string
) => {
    try {
        const data = await HTTPService.post(
            `${ENDPOINT}/users/two-factor/passkeys/finish`,
            {
                id: credential.id,
                rawId: credential.id,
                type: credential.type,
                response: {
                    authenticatorData: _sodium.to_base64(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.authenticatorData),
                        _sodium.base64_variants.URLSAFE_NO_PADDING
                    ),
                    clientDataJSON: _sodium.to_base64(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.clientDataJSON),
                        _sodium.base64_variants.URLSAFE_NO_PADDING
                    ),
                    signature: _sodium.to_base64(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.signature),
                        _sodium.base64_variants.URLSAFE_NO_PADDING
                    ),
                    userHandle: _sodium.to_base64(
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        new Uint8Array(credential.response.userHandle),
                        _sodium.base64_variants.URLSAFE_NO_PADDING
                    ),
                },
            },
            {
                sessionID: sessionId,
                ceremonySessionID: ceremonySessionId,
            }
        );

        return data.data;
    } catch (e) {
        logError(e, 'finish passkey authentication failed');
        throw e;
    }
};
