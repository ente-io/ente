import { PAGES } from 'constants/pages';
import {
    getEndpoint,
    getFamilyPortalURL,
    isDevDeployment,
} from 'utils/common/apiUtil';
import { clearKeys } from 'utils/storage/sessionStorage';
import router from 'next/router';
import { clearData, getData, LS_KEYS } from 'utils/storage/localStorage';
import localForage from 'utils/storage/localForage';
import { getToken } from 'utils/common/key';
import HTTPService from './HTTPService';
import {
    computeVerifierHelper,
    generateLoginSubKey,
    generateSRPClient,
    getRecoveryKey,
} from 'utils/crypto';
import { logError } from 'utils/sentry';
import { eventBus, Events } from './events';
import {
    KeyAttributes,
    RecoveryKey,
    TwoFactorSecret,
    TwoFactorVerificationResponse,
    TwoFactorRecoveryResponse,
    UserDetails,
    DeleteChallengeResponse,
    GetRemoteStoreValueResponse,
    SetupSRPRequest,
    CreateSRPSessionResponse,
    UserVerificationResponse,
    GetFeatureFlagResponse,
    SetupSRPResponse,
    CompleteSRPSetupRequest,
    CompleteSRPSetupResponse,
    SRPSetupAttributes,
    SRPAttributes,
    UpdateSRPAndKeysRequest,
    UpdateSRPAndKeysResponse,
    GetSRPAttributesResponse,
} from 'types/user';
import { ApiError, CustomError } from 'utils/error';
import isElectron from 'is-electron';
import safeStorageService from './electron/safeStorage';
import { deleteAllCache } from 'utils/storage/cache';
import { B64EncryptionResult } from 'types/crypto';
import { getLocalFamilyData, isPartOfFamily } from 'utils/user/family';
import { AxiosResponse, HttpStatusCode } from 'axios';
import { APPS, getAppName } from 'constants/apps';
import { addLocalLog } from 'utils/logging';
import { convertBase64ToBuffer, convertBufferToBase64 } from 'utils/user';
import { setLocalMapEnabled } from 'utils/storage';
import InMemoryStore, { MS_KEYS } from './InMemoryStore';

const ENDPOINT = getEndpoint();

const HAS_SET_KEYS = 'hasSetKeys';

export const sendOtt = (email: string) => {
    const appName = getAppName();
    return HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: appName === APPS.AUTH ? 'totp' : 'web',
    });
};

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

export const verifyOtt = (email: string, ott: string) =>
    HTTPService.post(`${ENDPOINT}/users/verify-email`, { email, ott });

export const putAttributes = (token: string, keyAttributes: KeyAttributes) =>
    HTTPService.put(`${ENDPOINT}/users/attributes`, { keyAttributes }, null, {
        'X-Auth-Token': token,
    });

export const setRecoveryKey = (token: string, recoveryKey: RecoveryKey) =>
    HTTPService.put(`${ENDPOINT}/users/recovery-key`, recoveryKey, null, {
        'X-Auth-Token': token,
    });

export const logoutUser = async () => {
    try {
        try {
            // ignore server logout result as logoutUser can be triggered before sign up or on token expiry
            await _logout();
        } catch (e) {
            //ignore
        }
        try {
            InMemoryStore.clear();
        } catch (e) {
            logError(e, 'clear InMemoryStore failed');
        }
        try {
            clearKeys();
        } catch (e) {
            logError(e, 'clearKeys failed');
        }
        try {
            clearData();
        } catch (e) {
            logError(e, 'clearData failed');
        }
        try {
            await deleteAllCache();
        } catch (e) {
            logError(e, 'deleteAllCache failed');
        }
        try {
            await clearFiles();
        } catch (e) {
            logError(e, 'clearFiles failed');
        }
        if (isElectron()) {
            try {
                safeStorageService.clearElectronStore();
            } catch (e) {
                logError(e, 'clearElectronStore failed');
            }
        }
        try {
            eventBus.emit(Events.LOGOUT);
        } catch (e) {
            logError(e, 'Error in logout handlers');
        }
        router.push(PAGES.ROOT);
    } catch (e) {
        logError(e, 'logoutUser failed');
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

export const setupTwoFactor = async () => {
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/two-factor/setup`,
        null,
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
    return resp.data as TwoFactorSecret;
};

export const enableTwoFactor = async (
    code: string,
    recoveryEncryptedTwoFactorSecret: B64EncryptionResult
) => {
    await HTTPService.post(
        `${ENDPOINT}/users/two-factor/enable`,
        {
            code,
            encryptedTwoFactorSecret:
                recoveryEncryptedTwoFactorSecret.encryptedData,
            twoFactorSecretDecryptionNonce:
                recoveryEncryptedTwoFactorSecret.nonce,
        },
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
};

export const verifyTwoFactor = async (code: string, sessionID: string) => {
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/two-factor/verify`,
        {
            code,
            sessionID,
        },
        null
    );
    return resp.data as TwoFactorVerificationResponse;
};

export const recoverTwoFactor = async (sessionID: string) => {
    const resp = await HTTPService.get(`${ENDPOINT}/users/two-factor/recover`, {
        sessionID,
    });
    return resp.data as TwoFactorRecoveryResponse;
};

export const removeTwoFactor = async (sessionID: string, secret: string) => {
    const resp = await HTTPService.post(`${ENDPOINT}/users/two-factor/remove`, {
        sessionID,
        secret,
    });
    return resp.data as TwoFactorVerificationResponse;
};

export const disableTwoFactor = async () => {
    await HTTPService.post(`${ENDPOINT}/users/two-factor/disable`, null, null, {
        'X-Auth-Token': getToken(),
    });
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

export const _logout = async () => {
    if (!getToken()) return true;
    try {
        await HTTPService.post(`${ENDPOINT}/users/logout`, null, null, {
            'X-Auth-Token': getToken(),
        });
        return true;
    } catch (e) {
        logError(e, '/users/logout failed');
        return false;
    }
};

export const sendOTTForEmailChange = async (email: string) => {
    if (!getToken()) {
        return null;
    }
    await HTTPService.post(`${ENDPOINT}/users/ott`, {
        email,
        client: 'web',
        purpose: 'change',
    });
};

export const changeEmail = async (email: string, ott: string) => {
    if (!getToken()) {
        return null;
    }
    await HTTPService.post(
        `${ENDPOINT}/users/change-email`,
        {
            email,
            ott,
        },
        null,
        {
            'X-Auth-Token': getToken(),
        }
    );
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
    try {
        const disableCFUploadProxy =
            process.env.NEXT_PUBLIC_DISABLE_CF_UPLOAD_PROXY;
        if (isDevDeployment() && typeof disableCFUploadProxy !== 'undefined') {
            return disableCFUploadProxy === 'true';
        }
        const featureFlags = (
            await fetch('https://static.ente.io/feature_flags.json')
        ).json() as GetFeatureFlagResponse;
        return featureFlags.disableCFUploadProxy;
    } catch (e) {
        logError(e, 'failed to get feature flags');
        return false;
    }
}

export const getSRPAttributes = async (
    email: string
): Promise<SRPAttributes | null> => {
    try {
        const resp = await HTTPService.get(`${ENDPOINT}/users/srp/attributes`, {
            email,
        });
        return (resp.data as GetSRPAttributesResponse).attributes;
    } catch (e) {
        logError(e, 'failed to get SRP attributes');
        return null;
    }
};

export const configureSRP = async ({
    srpSalt,
    srpUserID,
    srpVerifier,
    loginSubKey,
}: SRPSetupAttributes) => {
    try {
        const srpConfigureInProgress = InMemoryStore.get(
            MS_KEYS.SRP_CONFIGURE_IN_PROGRESS
        );
        if (srpConfigureInProgress) {
            throw Error('SRP configure already in progress');
        }
        InMemoryStore.set(MS_KEYS.SRP_CONFIGURE_IN_PROGRESS, true);
        const srpClient = await generateSRPClient(
            srpSalt,
            srpUserID,
            loginSubKey
        );

        const srpA = convertBufferToBase64(srpClient.computeA());

        addLocalLog(() => `srp a: ${srpA}`);
        const token = getToken();
        const { setupID, srpB } = await startSRPSetup(token, {
            srpA,
            srpUserID,
            srpSalt,
            srpVerifier,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        const { srpM2 } = await completeSRPSetup(token, {
            srpM1,
            setupID,
        });

        srpClient.checkM2(convertBase64ToBuffer(srpM2));
    } catch (e) {
        logError(e, 'srp configure failed');
        throw e;
    } finally {
        InMemoryStore.set(MS_KEYS.SRP_CONFIGURE_IN_PROGRESS, false);
    }
};

export const startSRPSetup = async (
    token: string,
    setupSRPRequest: SetupSRPRequest
): Promise<SetupSRPResponse> => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/setup`,
            setupSRPRequest,
            null,
            {
                'X-Auth-Token': token,
            }
        );

        return resp.data as SetupSRPResponse;
    } catch (e) {
        logError(e, 'failed to post SRP attributes');
        throw e;
    }
};

export const completeSRPSetup = async (
    token: string,
    completeSRPSetupRequest: CompleteSRPSetupRequest
) => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/complete`,
            completeSRPSetupRequest,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data as CompleteSRPSetupResponse;
    } catch (e) {
        logError(e, 'failed to complete SRP setup');
        throw e;
    }
};

export const loginViaSRP = async (
    srpAttributes: SRPAttributes,
    kek: string
): Promise<UserVerificationResponse> => {
    try {
        const loginSubKey = await generateLoginSubKey(kek);
        const srpClient = await generateSRPClient(
            srpAttributes.srpSalt,
            srpAttributes.srpUserID,
            loginSubKey
        );
        const srpVerifier = computeVerifierHelper(
            srpAttributes.srpSalt,
            srpAttributes.srpUserID,
            loginSubKey
        );
        addLocalLog(() => `srp verifier: ${srpVerifier}`);
        const srpA = srpClient.computeA();
        const { srpB, sessionID } = await createSRPSession(
            srpAttributes.srpUserID,
            convertBufferToBase64(srpA)
        );
        srpClient.setB(convertBase64ToBuffer(srpB));

        const m1 = srpClient.computeM1();
        addLocalLog(() => `srp m1: ${convertBufferToBase64(m1)}`);
        const { srpM2, ...rest } = await verifySRPSession(
            sessionID,
            srpAttributes.srpUserID,
            convertBufferToBase64(m1)
        );
        addLocalLog(() => `srp verify session successful,srpM2: ${srpM2}`);

        srpClient.checkM2(convertBase64ToBuffer(srpM2));

        addLocalLog(() => `srp server verify successful`);

        return rest;
    } catch (e) {
        logError(e, 'srp verify failed');
        throw e;
    }
};

export const createSRPSession = async (srpUserID: string, srpA: string) => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/create-session`,
            {
                srpUserID,
                srpA,
            }
        );
        return resp.data as CreateSRPSessionResponse;
    } catch (e) {
        logError(e, 'createSRPSession failed');
        throw e;
    }
};

export const verifySRPSession = async (
    sessionID: string,
    srpUserID: string,
    srpM1: string
) => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/verify-session`,
            {
                sessionID,
                srpUserID,
                srpM1,
            },
            null
        );
        return resp.data as UserVerificationResponse;
    } catch (e) {
        logError(e, 'verifySRPSession failed');
        if (
            e instanceof ApiError &&
            e.httpStatusCode === HttpStatusCode.Unauthorized
        ) {
            throw Error(CustomError.INCORRECT_PASSWORD);
        } else {
            throw e;
        }
    }
};

export const updateSRPAndKeys = async (
    token: string,
    updateSRPAndKeyRequest: UpdateSRPAndKeysRequest
): Promise<UpdateSRPAndKeysResponse> => {
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/srp/update`,
        updateSRPAndKeyRequest,
        null,
        {
            'X-Auth-Token': token,
        }
    );
    return resp.data as UpdateSRPAndKeysResponse;
};
