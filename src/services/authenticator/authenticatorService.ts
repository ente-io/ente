import HTTPService from 'services/HTTPService';
import { AuthEntity } from 'types/authenticator/auth_entity';
import { Code } from 'types/authenticator/code';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { getEndpoint } from 'utils/common/apiUtil';
import { getActualKey, getToken } from 'utils/common/key';
import { logError } from 'utils/sentry';

const ENDPOINT = getEndpoint();
export const getAuthCodes = async (): Promise<Code[]> => {
    const masterKey = await getActualKey();
    try {
        const authKeyData = await getAuthKey();
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const authentitorKey = await cryptoWorker.decryptB64(
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
                    const decryptedCode = await cryptoWorker.decryptMetadata(
                        entity.encryptedData,
                        entity.header,
                        authentitorKey
                    );
                    return Code.fromRawData(entity.id, decryptedCode);
                })
        );
        // sort by issuer name which can be undefined also
        authCodes.sort((a, b) => {
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
        return authCodes;
    } catch (e) {
        logError(e, 'get authenticator entities failed');
        throw e;
    }
};

export const getAuthKey = async () => {
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
        logError(e, 'Get key failed');
        throw e;
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
