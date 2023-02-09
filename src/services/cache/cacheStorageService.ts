import { logError } from 'utils/sentry';
import { CacheStorageFactory } from './cacheStorageFactory';

async function openCache(cacheName: string) {
    try {
        return await CacheStorageFactory.getCacheStorage().open(cacheName);
    } catch (e) {
        // log and ignore, we don't want to crash the app if cache is not available
        logError(e, 'openCache failed');
    }
}
async function deleteCache(cacheName: string) {
    try {
        return await CacheStorageFactory.getCacheStorage().delete(cacheName);
    } catch (e) {
        // log and ignore, we don't want to crash the app if cache is not available
        logError(e, 'deleteCache failed');
    }
}

export const CacheStorageService = { open: openCache, delete: deleteCache };
