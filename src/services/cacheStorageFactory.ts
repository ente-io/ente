import { LimitedCacheStorage } from 'types/cache/index';
import electronService from 'services/electron/common';
import ElectronCacheStorage from 'services/electron/cache';
import { runningInWorker } from 'utils/common';
import ReverseProxiedElectronCacheStorageProxy from 'worker/electronCacheStorageProxy.proxy';

export function getCacheStorage(): LimitedCacheStorage {
    if (electronService.checkIsBundledApp()) {
        if (runningInWorker()) {
            return ReverseProxiedElectronCacheStorageProxy;
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
            const {
                match,
                put,
                delete: cacheDelete,
            } = await caches.open(cacheName);
            return { match, put, delete: cacheDelete };
        },
        delete: caches.delete,
    };
}
