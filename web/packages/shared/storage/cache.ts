const cacheNames = [
    "thumbs",
    "face-crops",
    // Desktop app only
    "files",
] as const;

/** Namespaces into which our caches data is divided */
export type CacheName = (typeof cacheNames)[number];

export interface LimitedCache {
    match: (key: string) => Promise<Response>;
    put: (key: string, data: Response) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

const openCache = async (name: CacheName) => {
    const cache = await caches.open(name);
    return {
        match: (key) => {
            // options are not supported in the browser
            return cache.match(key);
        },
        put: cache.put.bind(cache),
        delete: cache.delete.bind(cache),
    };
};

export const CacheStorageService = { open: openCache };

export async function cached(
    cacheName: CacheName,
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
