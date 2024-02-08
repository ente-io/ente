import * as Comlink from 'comlink';
import { LimitedCache } from '@ente/shared/storage/cacheStorage/types';
import { serializeResponse, deserializeToResponse } from './utils/proxy';
import ElectronAPIs from '@ente/shared/electron';

export interface ProxiedLimitedElectronAPIs {
    openDiskCache: (
        cacheName: string,
        cacheLimitInBytes?: number
    ) => Promise<ProxiedWorkerLimitedCache>;
    deleteDiskCache: (cacheName: string) => Promise<boolean>;
    getSentryUserID: () => Promise<string>;
    convertToJPEG: (
        inputFileData: Uint8Array,
        filename: string
    ) => Promise<Uint8Array>;
    logToDisk: (message: string) => void;
}
export interface ProxiedWorkerLimitedCache {
    match: (
        key: string,
        options?: { sizeInBytes?: number }
    ) => Promise<ArrayBuffer>;
    put: (key: string, data: ArrayBuffer) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

export class WorkerSafeElectronClient implements ProxiedLimitedElectronAPIs {
    async openDiskCache(cacheName: string, cacheLimitInBytes?: number) {
        const cache = await ElectronAPIs.openDiskCache(
            cacheName,
            cacheLimitInBytes
        );
        return Comlink.proxy({
            match: Comlink.proxy(transformMatch(cache.match.bind(cache))),
            put: Comlink.proxy(transformPut(cache.put.bind(cache))),
            delete: Comlink.proxy(cache.delete.bind(cache)),
        });
    }

    async deleteDiskCache(cacheName: string) {
        return await ElectronAPIs.deleteDiskCache(cacheName);
    }

    async getSentryUserID() {
        return await ElectronAPIs.getSentryUserID();
    }

    async convertToJPEG(
        inputFileData: Uint8Array,
        filename: string
    ): Promise<Uint8Array> {
        return await ElectronAPIs.convertToJPEG(inputFileData, filename);
    }
    logToDisk(message: string) {
        return ElectronAPIs.logToDisk(message);
    }
}

function transformMatch(
    fn: LimitedCache['match']
): ProxiedWorkerLimitedCache['match'] {
    return async (key: string, options: { sizeInBytes?: number }) => {
        return serializeResponse(await fn(key, options));
    };
}

function transformPut(
    fn: LimitedCache['put']
): ProxiedWorkerLimitedCache['put'] {
    return async (key: string, data: ArrayBuffer) => {
        fn(key, deserializeToResponse(data));
    };
}
