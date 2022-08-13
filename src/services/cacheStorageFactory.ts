import { LimitedCacheStorage } from 'types/cache/index';
import electronService from 'services/electron/common';
import ElectronCacheStorage from 'services/electron/cache';
import { runningInWorker } from 'utils/common';
import ReverseProxiedElectronCacheStorageProxy from 'worker/electronCacheStorageProxy.proxy';

export function getCacheStorage(): LimitedCacheStorage {
    if (electronService.checkIsBundledApp()) {
        if (runningInWorker()) {
            return new ReverseProxiedElectronCacheStorageProxy();
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
