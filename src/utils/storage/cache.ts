import { FACE_CROPS_CACHE, FILE_CACHE, THUMB_CACHE } from 'constants/cache';
import { CacheStorageService } from 'services/cache/cacheStorageService';
import { logError } from 'utils/sentry';

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

export async function getBlobFromCache(
    cacheName: string,
    url: string
): Promise<Blob> {
    const cache = await CacheStorageService.open(cacheName);
    const response = await cache.match(url);

    return response.blob();
}

export async function deleteAllCache() {
    try {
        await CacheStorageService.delete(THUMB_CACHE);
        await CacheStorageService.delete(FACE_CROPS_CACHE);
        await CacheStorageService.delete(FILE_CACHE);
    } catch (e) {
        logError(e, 'deleteAllCache failed'); // log and ignore
    }
}
