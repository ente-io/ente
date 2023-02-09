import { LimitedCacheStorage } from 'types/cache/index';
import { ElectronCacheStorage } from 'services/electron/cache';
import isElectron from 'is-electron';

export function getCacheStorage(): LimitedCacheStorage {
    if (isElectron()) {
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
            const cache = await caches.open(cacheName);
            return {
                match: cache.match.bind(cache),
                put: cache.put.bind(cache),
                delete: cache.delete.bind(cache),
            };
        },
        delete: caches.delete.bind(caches),
    };
}
