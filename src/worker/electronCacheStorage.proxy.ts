import ElectronCacheStorage from 'services/electron/cache';
import * as Comlink from 'comlink';
import { LimitedCache, ProxiedWorkerLimitedCache } from 'types/cache';

export default class ElectronCacheStorageProxy {
    async open(cacheName: string) {
        const cache = await ElectronCacheStorage.open(cacheName);
        return Comlink.proxy({
            match: Comlink.proxy(transformMatch(cache.match.bind(cache))),
            put: Comlink.proxy(transformPut(cache.put.bind(cache))),
        });
    }

    async delete(cacheName: string) {
        return await ElectronCacheStorage.delete(cacheName);
    }
}

function transformMatch(
    fn: LimitedCache['match']
): ProxiedWorkerLimitedCache['match'] {
    return async (key: string) => {
        return serializeResponse(await fn(key));
    };
}

function transformPut(
    fn: LimitedCache['put']
): ProxiedWorkerLimitedCache['put'] {
    return async (key: string, data: ArrayBuffer) => {
        fn(key, deserializeToResponse(data));
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
