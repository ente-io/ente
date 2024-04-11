import log from "@/next/log";

export enum CACHES {
    THUMBS = "thumbs",
    FACE_CROPS = "face-crops",
    // Desktop app only
    FILES = "files",
}

export interface LimitedCacheStorage {
    open: (
        cacheName: string,
        cacheLimitInBytes?: number,
    ) => Promise<LimitedCache>;
    delete: (cacheName: string) => Promise<boolean>;
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
        return transformBrowserCacheStorageToLimitedCacheStorage(caches);
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

const SecurityError = "SecurityError";
const INSECURE_OPERATION = "The operation is insecure.";

async function openCache(cacheName: string, cacheLimit?: number) {
    try {
        return await CacheStorageFactory.getCacheStorage().open(
            cacheName,
            cacheLimit,
        );
    } catch (e) {
        // ignoring insecure operation error, as it is thrown in incognito mode in firefox
        if (e.name === SecurityError && e.message === INSECURE_OPERATION) {
            // no-op
        } else {
            // log and ignore, we don't want to break the caller flow, when cache is not available
            log.error("openCache failed", e);
        }
    }
}
async function deleteCache(cacheName: string) {
    try {
        return await CacheStorageFactory.getCacheStorage().delete(cacheName);
    } catch (e) {
        // ignoring insecure operation error, as it is thrown in incognito mode in firefox
        if (e.name === SecurityError && e.message === INSECURE_OPERATION) {
            // no-op
        } else {
            // log and ignore, we don't want to break the caller flow, when cache is not available
            log.error("deleteCache failed", e);
        }
    }
}

export const CacheStorageService = { open: openCache, delete: deleteCache };

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
    await CacheStorageService.delete(CACHES.THUMBS);
    await CacheStorageService.delete(CACHES.FACE_CROPS);
    await CacheStorageService.delete(CACHES.FILES);
};
