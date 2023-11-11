import { HttpStatusCode } from 'axios';
import HTTPService from '@ente/shared/network/HTTPService';
import { AuthEntity, AuthKey } from 'types/api';
import { Code } from 'types/code';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import { getEndpoint } from '@ente/shared/network/api';
import { getActualKey } from '@ente/shared/user';
import { getToken } from '@ente/shared/storage/localStorage/helpers';
import { ApiError, CustomError } from '@ente/shared/error';
import { logError } from '@ente/shared/sentry';

const ENDPOINT = getEndpoint();
export const getAuthCodes = async (): Promise<Code[]> => {
    const masterKey = await getActualKey();
    try {
        const authKeyData = await getAuthKey();
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const authenticatorKey = await cryptoWorker.decryptB64(
            authKeyData.encryptedKey,
            authKeyData.header,
            masterKey
        );
        // always fetch all data from server for now
        const authEntity: AuthEntity[] = await getDiff(0);
        const authCodes = await Promise.all(
            authEntity
                .filter((f) => !f.isDeleted)
                .map(async (entity) => {
                    try {
                        const decryptedCode =
                            await cryptoWorker.decryptMetadata(
                                entity.encryptedData,
                                entity.header,
                                authenticatorKey
                            );
                        return Code.fromRawData(entity.id, decryptedCode);
                    } catch (e) {
                        logError(
                            Error('failed to parse code'),
                            'codeId = ' + entity.id
                        );
                        return null;
                    }
                })
        );
        // Remove null and undefined values
        const filteredAuthCodes = authCodes.filter(
            (f) => f !== null && f !== undefined
        );
        filteredAuthCodes.sort((a, b) => {
            if (a.issuer && b.issuer) {
                return a.issuer.localeCompare(b.issuer);
            }
            if (a.issuer) {
                return -1;
            }
            if (b.issuer) {
                return 1;
            }
            return 0;
        });
        return filteredAuthCodes;
    } catch (e) {
        if (e.message !== CustomError.AUTH_KEY_NOT_FOUND) {
            logError(e, 'get authenticator entities failed');
        }
        throw e;
    }
};

export const getAuthKey = async (): Promise<AuthKey> => {
    try {
        const resp = await HTTPService.get(
            `${ENDPOINT}/authenticator/key`,
            {},
            {
                'X-Auth-Token': getToken(),
            }
        );
        return resp.data;
    } catch (e) {
        if (
            e instanceof ApiError &&
            e.httpStatusCode === HttpStatusCode.NotFound
        ) {
            throw Error(CustomError.AUTH_KEY_NOT_FOUND);
        } else {
            logError(e, 'Get key failed');
            throw e;
        }
    }
};

// return a promise which resolves to list of AuthEnitity
export const getDiff = async (
    sinceTime: number,
    limit = 2500
): Promise<AuthEntity[]> => {
    try {
        const resp = await HTTPService.get(
            `${ENDPOINT}/authenticator/entity/diff`,
            {
                sinceTime,
                limit,
            },
            {
                'X-Auth-Token': getToken(),
            }
        );
        return resp.data.diff;
    } catch (e) {
        logError(e, 'Get diff failed');
        throw e;
    }
};
