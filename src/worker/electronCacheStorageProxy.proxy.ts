import * as Comlink from 'comlink';
import {
    LimitedCache,
    LimitedCacheStorage,
    ProxiedWorkerLimitedCache,
} from 'types/cache';
import ElectronCacheStorageProxy from './electronCacheStorage.proxy';
import { wrap } from 'comlink';

class ElectronCacheStorageReverseProxy implements LimitedCacheStorage {
    proxiedElectronCacheService: Comlink.Remote<ElectronCacheStorageProxy>;
    ready: Promise<any>;

    constructor() {
        this.ready = this.init();
    }
    async init() {
        const electronCacheStorageProxy =
            wrap<typeof ElectronCacheStorageProxy>(self);

        this.proxiedElectronCacheService =
            await new electronCacheStorageProxy();
    }
    async open(cacheName: string) {
        await this.ready;
        const cache = await this.proxiedElectronCacheService.open(cacheName);
        return {
            match: transformMatch(cache.match.bind(cache)),
            put: transformPut(cache.put.bind(cache)),
            delete: cache.delete.bind(cache),
        };
    }

    async delete(cacheName: string) {
        return await this.proxiedElectronCacheService.delete(cacheName);
    }
}

export default new ElectronCacheStorageReverseProxy();

function transformMatch(
    fn: ProxiedWorkerLimitedCache['match']
): LimitedCache['match'] {
    return async (key: string) => {
        return deserializeToResponse(await fn(key));
    };
}

function transformPut(
    fn: ProxiedWorkerLimitedCache['put']
): LimitedCache['put'] {
    return async (key: string, data: Response) => {
        fn(key, await serializeResponse(data));
    };
}

function serializeResponse(response: Response) {
    return response.arrayBuffer();
}

function deserializeToResponse(arrayBuffer: ArrayBuffer) {
    return new Response(arrayBuffer);
}

// Comlink.transferHandlers.set('RESPONSE', {
//     canHandle: (obj) => obj instanceof Response,
//     serialize: (response: Response) => [response.arrayBuffer(), []],
//     deserialize: (arrayBuffer: ArrayBuffer) => new Response(arrayBuffer),
// });
