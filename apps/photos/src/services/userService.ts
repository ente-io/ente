import { putAttributes } from '@ente/accounts/api/user';
import { logoutUser } from '@ente/accounts/services/user';
import { getRecoveryKey } from '@ente/shared/crypto/helpers';
import { ApiError } from '@ente/shared/error';
import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint, getFamilyPortalURL } from '@ente/shared/network/api';
import { logError } from '@ente/shared/sentry';
import localForage from '@ente/shared/storage/localForage';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import {
    getToken,
    setLocalMapEnabled,
} from '@ente/shared/storage/localStorage/helpers';
import { AxiosResponse, HttpStatusCode } from 'axios';
import {
    DeleteChallengeResponse,
    GetFeatureFlagResponse,
    GetRemoteStoreValueResponse,
    UserDetails,
} from 'types/user';
import { getLocalFamilyData, isPartOfFamily } from 'utils/user/family';

const ENDPOINT = getEndpoint();

const HAS_SET_KEYS = 'hasSetKeys';

export const getPublicKey = async (email: string) => {
    const token = getToken();

    const resp = await HTTPService.get(
        `${ENDPOINT}/users/public-key`,
        { email },
        {
            'X-Auth-Token': token,
        }
    );
    return resp.data.publicKey;
};

export const getPaymentToken = async () => {
    const token = getToken();

    const resp = await HTTPService.get(
        `${ENDPOINT}/users/payment-token`,
        null,
        {
            'X-Auth-Token': token,
        }
    );
    return resp.data['paymentToken'];
};

export const getFamiliesToken = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            `${ENDPOINT}/users/families-token`,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data['familiesToken'];
    } catch (e) {
        logError(e, 'failed to get family token');
        throw e;
    }
};

export const getAccountsToken = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            `${ENDPOINT}/users/accounts-token`,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data['accountsToken'];
    } catch (e) {
        logError(e, 'failed to get accounts token');
        throw e;
    }
};

export const getRoadmapRedirectURL = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            `${ENDPOINT}/users/roadmap/v2`,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data['url'];
    } catch (e) {
        logError(e, 'failed to get roadmap url');
        throw e;
    }
};

export const clearFiles = async () => {
    await localForage.clear();
};

export const isTokenValid = async (token: string) => {
    try {
        const resp = await HTTPService.get(
            `${ENDPOINT}/users/session-validity/v2`,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        try {
            if (resp.data[HAS_SET_KEYS] === undefined) {
                throw Error('resp.data.hasSetKey undefined');
            }
            if (!resp.data['hasSetKeys']) {
                try {
                    await putAttributes(
                        token,
                        getData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES)
                    );
                } catch (e) {
                    logError(e, 'put attribute failed');
                }
            }
        } catch (e) {
            logError(e, 'hasSetKeys not set in session validity response');
        }
        return true;
    } catch (e) {
        logError(e, 'session-validity api call failed');
        if (
            e instanceof ApiError &&
            e.httpStatusCode === HttpStatusCode.Unauthorized
        ) {
            return false;
        } else {
            return true;
        }
    }
};

export const getTwoFactorStatus = async () => {
    const resp = await HTTPService.get(
        `${ENDPOINT}/users/two-factor/status`,
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
    return resp.data['status'];
};

export const getUserDetailsV2 = async (): Promise<UserDetails> => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            `${ENDPOINT}/users/details/v2`,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data;
    } catch (e) {
        logError(e, 'failed to get user details v2');
        throw e;
    }
};

export const getFamilyPortalRedirectURL = async () => {
    try {
        const jwtToken = await getFamiliesToken();
        const isFamilyCreated = isPartOfFamily(getLocalFamilyData());
        return `${getFamilyPortalURL()}?token=${jwtToken}&isFamilyCreated=${isFamilyCreated}&redirectURL=${
            window.location.origin
        }/gallery`;
    } catch (e) {
        logError(e, 'unable to generate to family portal URL');
        throw e;
    }
};

export const getAccountDeleteChallenge = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            `${ENDPOINT}/users/delete-challenge`,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data as DeleteChallengeResponse;
    } catch (e) {
        logError(e, 'failed to get account delete challenge');
        throw e;
    }
};

export const deleteAccount = async (
    challenge: string,
    reason: string,
    feedback: string
) => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }

        await HTTPService.delete(
            `${ENDPOINT}/users/delete`,
            { challenge, reason, feedback },
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'deleteAccount api call failed');
        throw e;
    }
};

// Ensure that the keys in local storage are not malformed by verifying that the
// recoveryKey can be decrypted with the masterKey.
// Note: This is not bullet-proof.
export const validateKey = async () => {
    try {
        await getRecoveryKey();
        return true;
    } catch (e) {
        await logoutUser();
        return false;
    }
};

export const getFaceSearchEnabledStatus = async () => {
    try {
        const token = getToken();
        const resp: AxiosResponse<GetRemoteStoreValueResponse> =
            await HTTPService.get(
                `${ENDPOINT}/remote-store`,
                {
                    key: 'faceSearchEnabled',
                    defaultValue: false,
                },
                {
                    'X-Auth-Token': token,
                }
            );
        return resp.data.value === 'true';
    } catch (e) {
        logError(e, 'failed to get face search enabled status');
        throw e;
    }
};

export const updateFaceSearchEnabledStatus = async (newStatus: boolean) => {
    try {
        const token = getToken();
        await HTTPService.post(
            `${ENDPOINT}/remote-store/update`,
            {
                key: 'faceSearchEnabled',
                value: newStatus.toString(),
            },
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'failed to update face search enabled status');
        throw e;
    }
};

export const syncMapEnabled = async () => {
    try {
        const status = await getMapEnabledStatus();
        setLocalMapEnabled(status);
    } catch (e) {
        logError(e, 'failed to sync map enabled status');
        throw e;
    }
};

export const getMapEnabledStatus = async () => {
    try {
        const token = getToken();
        const resp: AxiosResponse<GetRemoteStoreValueResponse> =
            await HTTPService.get(
                `${ENDPOINT}/remote-store`,
                {
                    key: 'mapEnabled',
                    defaultValue: false,
                },
                {
                    'X-Auth-Token': token,
                }
            );
        return resp.data.value === 'true';
    } catch (e) {
        logError(e, 'failed to get map enabled status');
        throw e;
    }
};

export const updateMapEnabledStatus = async (newStatus: boolean) => {
    try {
        const token = getToken();
        await HTTPService.post(
            `${ENDPOINT}/remote-store/update`,
            {
                key: 'mapEnabled',
                value: newStatus.toString(),
            },
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'failed to update map enabled status');
        throw e;
    }
};

export async function getDisableCFUploadProxyFlag(): Promise<boolean> {
    if (process.env.NEXT_PUBLIC_ENTE_DIRECT_UPLOAD === 'true') return true;

    try {
        const featureFlags = (
            await fetch('https://static.ente.io/feature_flags.json')
        ).json() as GetFeatureFlagResponse;
        return featureFlags.disableCFUploadProxy;
    } catch (e) {
        logError(e, 'failed to get feature flags');
        return false;
    }
}
