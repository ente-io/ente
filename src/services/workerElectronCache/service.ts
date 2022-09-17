import * as Comlink from 'comlink';
import {
    LimitedCache,
    LimitedCacheStorage,
    ProxiedWorkerLimitedCache,
} from 'types/cache';
import { WorkerElectronCacheStorageClient } from './client';
import { wrap } from 'comlink';
import {
    deserializeToResponse,
    serializeResponse,
} from 'utils/workerElectronCache/proxy';

export class WorkerElectronCacheStorageService implements LimitedCacheStorage {
    proxiedElectronCacheService: Comlink.Remote<WorkerElectronCacheStorageClient>;
    ready: Promise<any>;

    constructor() {
        this.ready = this.init();
    }
    async init() {
        const electronCacheStorageProxy =
            wrap<typeof WorkerElectronCacheStorageClient>(self);

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
        await this.ready;
        return await this.proxiedElectronCacheService.delete(cacheName);
    }
}

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
