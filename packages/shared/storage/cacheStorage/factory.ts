import { LimitedCacheStorage } from './types';
import { runningInElectron, runningInWorker } from '@ente/shared/platform';
import { WorkerElectronCacheStorageService } from './workerElectron/service';
import ElectronAPIs from '@ente/shared/electron';

class cacheStorageFactory {
    workerElectronCacheStorageServiceInstance: WorkerElectronCacheStorageService;
    getCacheStorage(): LimitedCacheStorage {
        if (runningInElectron()) {
            if (runningInWorker()) {
                if (!this.workerElectronCacheStorageServiceInstance) {
                    this.workerElectronCacheStorageServiceInstance =
                        new WorkerElectronCacheStorageService();
                }
                return this.workerElectronCacheStorageServiceInstance;
            } else {
                return {
                    open(cacheName) {
                        return ElectronAPIs.openDiskCache(cacheName);
                    },
                    delete(cacheName) {
                        return ElectronAPIs.deleteDiskCache(cacheName);
                    },
                };
            }
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
