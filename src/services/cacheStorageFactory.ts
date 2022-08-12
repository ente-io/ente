import { LimitedCacheStorage } from 'types/cache/index';
import electronService from 'services/electron/common';
import ElectronCacheStorage from 'services/electron/cache';

export function getCacheStorage(): LimitedCacheStorage {
    if (electronService.checkIsBundledApp()) {
        return ElectronCacheStorage;
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
