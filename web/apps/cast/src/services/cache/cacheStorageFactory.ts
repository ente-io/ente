import { LimitedCacheStorage } from "types/cache/index";

class cacheStorageFactory {
    getCacheStorage(): LimitedCacheStorage {
        return transformBrowserCacheStorageToLimitedCacheStorage(caches);
    }
}

export const CacheStorageFactory = new cacheStorageFactory();

function transformBrowserCacheStorageToLimitedCacheStorage(
    caches: CacheStorage,
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
