import { LimitedCacheStorage } from "./types";

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
                match: (key) => {
                    // options are not supported in the browser
                    return cache.match(key);
                },
                put: cache.put.bind(cache),
                delete: cache.delete.bind(cache),
            };
        },
        delete: caches.delete.bind(caches),
    };
}
