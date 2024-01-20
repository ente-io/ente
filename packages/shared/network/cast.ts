import { logError } from '../sentry';
import HTTPService from './HTTPService';
import { getEndpoint } from './api';

class CastGateway {
    constructor() {}

    public async getCastData(code: string): Promise<string> {
        let resp;
        try {
            resp = await HTTPService.get(`${getEndpoint()}/kex/get`, {
                identifier: `${code}_payload`,
            });
        } catch (e) {
            logError(e, 'failed to getCastData');
            throw e;
        }
        return resp.data.wrappedKey;
    }

    public async getPublicKey(code: string): Promise<string> {
        let resp;
        try {
            resp = await HTTPService.get(`${getEndpoint()}/kex/get`, {
                identifier: `${code}_pubkey`,
            });
        } catch (e) {
            logError(e, 'failed to getPublicKey');
            throw e;
        }
        return resp.data.wrappedKey;
    }

    public async advertisePublicKey(code: string, publicKey: string) {
        await HTTPService.put(getEndpoint() + '/kex/add', {
            customIdentifier: `${code}_pubkey`,
            wrappedKey: publicKey,
        });
    }

    public async publishCastPayload(code: string, castPayload: string) {
        await HTTPService.put(getEndpoint() + '/kex/add', {
            customIdentifier: `${code}_payload`,
            wrappedKey: castPayload,
        });
    }
}

export default new CastGateway();
