import * as Comlink from 'comlink';
import {
    LimitedCache,
    ProxiedLimitedCacheStorage,
    ProxiedWorkerLimitedCache,
} from '@ente/shared/storage/cacheStorage/types';
import { serializeResponse, deserializeToResponse } from './utils/proxy';
import ElectronAPIs from '@ente/shared/electron';

export class WorkerElectronCacheStorageClient
    implements ProxiedLimitedCacheStorage
{
    async open(cacheName: string) {
        const cache = await ElectronAPIs.openDiskCache(cacheName);
        return Comlink.proxy({
            match: Comlink.proxy(transformMatch(cache.match.bind(cache))),
            put: Comlink.proxy(transformPut(cache.put.bind(cache))),
            delete: Comlink.proxy(cache.delete.bind(cache)),
        });
    }

    async delete(cacheName: string) {
        return await ElectronAPIs.deleteDiskCache(cacheName);
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
