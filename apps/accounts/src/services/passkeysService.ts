import HTTPService from '@ente/shared/network/HTTPService';
import { getToken } from '@ente/shared/storage/localStorage/helpers';
import { getEndpoint } from '@ente/shared/network/api';
import { logError } from '@ente/shared/sentry';
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
        const rawIdB64 = _sodium.to_base64(
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            new Uint8Array(credential.rawId),
            _sodium.base64_variants.URLSAFE_NO_PADDING
        );
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
                rawId: rawIdB64,
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
