const cacheNames = [
    "thumbs",
    "face-crops",
    // Desktop app only
    "files",
] as const;

/** Namespaces into which our caches data is divided */
export type CacheName = (typeof cacheNames)[number];

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
    await Promise.all(cacheNames.map((name) => caches.delete(name)));
};
