import { WorkerSafeElectronService } from "@ente/shared/electron/service";
import { runningInElectron } from "@ente/shared/platform";
import { LimitedCacheStorage } from "./types";
class cacheStorageFactory {
    getCacheStorage(): LimitedCacheStorage {
        if (runningInElectron()) {
            return {
                open(cacheName, cacheLimitInBytes?: number) {
                    return WorkerSafeElectronService.openDiskCache(
                        cacheName,
                        cacheLimitInBytes,
                    );
                },
                delete(cacheName) {
                    return WorkerSafeElectronService.deleteDiskCache(cacheName);
                },
            };
        } else {
            return transformBrowserCacheStorageToLimitedCacheStorage(caches);
        }
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
