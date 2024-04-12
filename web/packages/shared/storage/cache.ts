export enum CACHES {
    THUMBS = "thumbs",
    FACE_CROPS = "face-crops",
    // Desktop app only
    FILES = "files",
}

interface LimitedCacheStorage {
    open: (cacheName: string) => Promise<LimitedCache>;
}

export interface LimitedCache {
    match: (
        key: string,
        options?: { sizeInBytes?: number },
    ) => Promise<Response>;
    put: (key: string, data: Response) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

class cacheStorageFactory {
    getCacheStorage(): LimitedCacheStorage {
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
        };
    }
}

export const CacheStorageFactory = new cacheStorageFactory();

async function openCache(cacheName: string) {
    return await CacheStorageFactory.getCacheStorage().open(cacheName);
}

export const CacheStorageService = { open: openCache };

export async function cached(
    cacheName: string,
    id: string,
    get: () => Promise<Blob>,
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
            console.error("Error while storing file to cache: ", id);
        }
    }

    return result;
}

/**
 * Delete all cached data.
 *
 * Meant for use during logout, to reset the state of the user's account.
 */
export const clearCaches = async () => {
    await Promise.all([
        caches.delete(CACHES.THUMBS),
        caches.delete(CACHES.FACE_CROPS),
        caches.delete(CACHES.FILES),
    ]);
};
