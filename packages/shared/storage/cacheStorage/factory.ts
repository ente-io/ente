import { LimitedCacheStorage } from './types';
import { runningInElectron } from '@ente/shared/platform';
import { WorkerSafeElectronService } from '@ente/shared/electron/service';
class cacheStorageFactory {
    getCacheStorage(): LimitedCacheStorage {
        if (runningInElectron()) {
            return {
                open(cacheName, cacheLimitInBytes?: number) {
                    return WorkerSafeElectronService.openDiskCache(
                        cacheName,
                        cacheLimitInBytes
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
