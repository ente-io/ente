const cacheNames = [
    "thumbs",
    "face-crops",
    // Desktop app only
    "files",
] as const;

/** Namespaces into which our caches data is divided */
export type CacheName = (typeof cacheNames)[number];

/**
 * A namespaced cache.
 *
 * To obtain a cache for a given namespace, use {@link openCache}. To clear all
 * cached data (e.g. during logout), use {@link clearCaches}.
 *
 * The underlying implementation of the cache is different depending on the
 * runtime environment.
 *
 * * The preferred implementation, and the one that is used when we're running
 *   in a browser, is to use the standard [Web
 *   Cache](https://developer.mozilla.org/en-US/docs/Web/API/Cache).
 *
 * * However when running under Electron (when this code runs as part of our
 *   desktop app), a custom OPFS based cache is used instead. This is because
 *   Electron currently doesn't support using standard Web Cache API for data
 *   served by a custom protocol handler (See this
 *   [issue](https://github.com/electron/electron/issues/35033), and the
 *   underlying restriction that comes from
 *   [Chromium](https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/modules/cache_storage/cache.cc;l=83-87?q=%22Request%20scheme%20%27%22&ss=chromium))
 *
 * [OPFS](https://web.dev/articles/origin-private-file-system) stands for Origin
 * Private File System. It is a recent API that allows a web site to store
 * reasonably large amounts of data. One option (that may still become possible
 * in the future) was to always use OPFS for caching instead of this dual
 * implementation, however currently [Safari does not support writing to OPFS
 * outside of web
 * workers](https://webkit.org/blog/12257/the-file-system-access-api-with-origin-private-file-system/)
 * ([the WebKit bug](https://bugs.webkit.org/show_bug.cgi?id=231706)), so it's
 * not trivial to use this as a full on replacement of the Web Cache in the
 * browser. So for now we go with this split implementation.
 */
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
