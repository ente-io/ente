import { logError } from 'utils/sentry';
import { CacheStorageFactory } from './cacheStorageFactory';

async function openCache(cacheName: string) {
    try {
        return await CacheStorageFactory.getCacheStorage().open(cacheName);
    } catch (e) {
        logError(e, 'openCache failed'); // log and ignore
    }
}
async function deleteCache(cacheName: string) {
    try {
        return await CacheStorageFactory.getCacheStorage().delete(cacheName);
    } catch (e) {
        logError(e, 'deleteCache failed'); // log and ignore
    }
}

export const CacheStorageService = { open: openCache, delete: deleteCache };
