import { CACHES } from './constants';
import { CacheStorageService } from '.';
import { logError } from '@ente/shared/sentry';
import { LimitedCache } from './types';

export async function cached(
    cacheName: string,
    id: string,
    get: () => Promise<Blob>
): Promise<Blob> {
    const cache = await CacheStorageService.open(cacheName);
    const cacheResponse = await cache.match(id);

    let result: Blob;
    if (cacheResponse) {
        result = await cacheResponse.blob();
    } else {
        result = await get();

        try {
            await cache.put(id, new Response(result));
        } catch (e) {
            // TODO: handle storage full exception.
            console.error('Error while storing file to cache: ', id);
        }
    }

    return result;
}

let thumbCache: LimitedCache;

export async function getBlobFromCache(
    cacheName: string,
    url: string
): Promise<Blob> {
    if (!thumbCache) {
        thumbCache = await CacheStorageService.open(cacheName);
    }
    const response = await thumbCache.match(url);
    if (!response) {
        return undefined;
    }
    return response.blob();
}

export async function deleteAllCache() {
    try {
        await CacheStorageService.delete(CACHES.THUMBS);
        await CacheStorageService.delete(CACHES.FACE_CROPS);
        await CacheStorageService.delete(CACHES.FILES);
    } catch (e) {
        logError(e, 'deleteAllCache failed'); // log and ignore
    }
}
