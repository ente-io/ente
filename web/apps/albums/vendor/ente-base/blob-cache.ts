const blobCacheNames = ["thumbs"] as const;

export type BlobCacheNamespace = (typeof blobCacheNames)[number];

export interface BlobCache {
    get: (key: string) => Promise<Blob | undefined>;
    has: (key: string) => Promise<boolean>;
    put: (key: string, blob: Blob) => Promise<void>;
    delete: (key: string) => Promise<boolean>;
}

const cachedCaches = new Map<BlobCacheNamespace, BlobCache>();

export const blobCache = async (
    name: BlobCacheNamespace,
): Promise<BlobCache> => {
    let cache = cachedCaches.get(name);
    if (!cache) {
        cache = await openBlobCache(name);
        cachedCaches.set(name, cache);
    }
    return cache;
};

export const openBlobCache = async (
    name: BlobCacheNamespace,
): Promise<BlobCache> => {
    const cache = await caches.open(name);
    return {
        get: async (key: string) => {
            const res = await cache.match(key);
            return await res?.blob();
        },
        has: async (key: string) => !!(await cache.match(key)),
        put: (key: string, blob: Blob) => cache.put(key, new Response(blob)),
        delete: (key: string) => cache.delete(key),
    };
};

export const clearBlobCaches = async () => {
    cachedCaches.clear();
    await Promise.all(blobCacheNames.map((name) => caches.delete(name)));
};
