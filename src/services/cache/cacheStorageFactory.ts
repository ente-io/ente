import { LimitedCacheStorage } from 'types/cache/index';
import ElectronCacheStorage from 'services/electron/cache/cache';
import { runningInElectron, runningInWorker } from 'utils/common';
import WorkerReverseProxyElectronCacheStorage from 'services/cache/workerReverseProxyElectronCacheStorage';

export function getCacheStorage(): LimitedCacheStorage {
    if (runningInElectron()) {
        if (runningInWorker()) {
            return new WorkerReverseProxyElectronCacheStorage();
        } else {
            return ElectronCacheStorage;
        }
    } else {
        return transformBrowserCacheStorageToLimitedCacheStorage(caches);
    }
}

function transformBrowserCacheStorageToLimitedCacheStorage(
    caches: CacheStorage
): LimitedCacheStorage {
    return {
        async open(cacheName) {
            const cache = await caches.open(cacheName);
            return {
                match: cache.match.bind(cache),
                put: cache.put.bind(cache),
                delete: cache.delete.bind(cache),
            };
        },
        delete: caches.delete,
    };
}
