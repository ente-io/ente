import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint } from '@ente/shared/network/api';
import { logError } from '@ente/shared/sentry';

const ENDPOINT = getEndpoint();

export const getKexValue = async (key: string) => {
    let resp;
    try {
        resp = await HTTPService.get(`${ENDPOINT}/kex/get`, {
            identifier: key,
        });
    } catch (e) {
        logError(e, 'failed to get kex value');
        throw e;
    }

    return resp.data.wrappedKey;
};

export const setKexValue = async (key: string, value: string) => {
    try {
        await HTTPService.put(ENDPOINT + '/kex/add', {
            customIdentifier: key,
            wrappedKey: value,
        });
    } catch (e) {
        logError(e, 'failed to set kex value');
        throw e;
    }
};
