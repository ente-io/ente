import isElectron from "is-electron";

const blobCacheNames = [
    "thumbs",
    "face-crops",
    // Desktop app only
    "files",
] as const;

/**
 * Namespaces into which our blob caches are divided
 *
 * Note that namespaces are just arbitrary (but predefined) strings to split the
 * cached data into "folders", so to speak.
 * */
export type BlobCacheNamespace = (typeof blobCacheNames)[number];

/**
 * A namespaced blob cache.
 *
 * This cache is suitable for storing large amounts of data (entire files).
 *
 * To obtain a cache for a given namespace, use {@link openCache}. To clear all
 * cached data (e.g. during logout), use {@link clearCaches}.
 *
 * [Note: Caching files]
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
 *
 * See also: [Note: Increased disk cache for the desktop app].
 */
export interface BlobCache {
    /**
     * Get the data corresponding to {@link key} (if found) from the cache.
     */
    get: (key: string) => Promise<Blob | undefined>;
    match: (key: string) => Promise<Response | undefined>;
    /**
     * Add the given {@link key}-value ({@link blob}) pair to the cache.
     */
    put2: (key: string, blob: Blob) => Promise<void>;
    put: (key: string, data: Response) => Promise<void>;
    /**
     * Delete the blob corresponding to the given {@link key}.
     *
     * The returned promise resolves to `true` if a cache entry was found,
     * otherwise it resolves to `false`.
     * */
    delete: (key: string) => Promise<boolean>;
}

/**
 * Return the {@link BlobCache} corresponding to the given {@link name}.
 *
 * @param name One of the arbitrary but predefined namespaces of type
 * {@link BlobCacheNamespace} which group related data and allow us to use the
 * same key across namespaces.
 */
export const openCache = async (
    name: BlobCacheNamespace,
): Promise<BlobCache> =>
    isElectron() ? openOPFSCacheWeb(name) : openWebCache(name);

/**
 * [Note: ArrayBuffer vs Blob vs Uint8Array]
 *
 * ArrayBuffers are in memory, while blobs are unreified, and can directly point
 * to on disk objects too.
 *
 * If we are just passing data around without necessarily needing to manipulate
 * it, and we already have a blob, it's best to just pass that blob. Further,
 * blobs also retains the file's encoding information , and are thus a layer
 * above array buffers which are just raw byte sequences.
 *
 * ArrayBuffers are not directly manipulatable, which is where some sort of a
 * typed array or a data view comes into the picture. The typed `Uint8Array` is
 * a common way.
 *
 * To convert from ArrayBuffer to Uint8Array,
 *
 *     new Uint8Array(arrayBuffer)
 *
 * Blobs are immutable, but a usual scenario is storing an entire file in a
 * blob, and when the need comes to display it, we can obtain a URL for it using
 *
 *     URL.createObjectURL(blob)
 *
 * Also note that a File is a Blob!
 *
 * To convert from a Blob to ArrayBuffer
 *
 *     await blob.arrayBuffer()
 *
 * Refs:
 * - https://github.com/yigitunallar/arraybuffer-vs-blob
 * - https://stackoverflow.com/questions/11821096/what-is-the-difference-between-an-arraybuffer-and-a-blob
 */

/** An implementation of {@link BlobCache} using Web Cache APIs */
const openWebCache = async (name: BlobCacheNamespace) => {
    const cache = await caches.open(name);
    return {
        get: async (key: string) => {
            const res = await cache.match(key);
            console.log("found cache hit", key, res);
            return await res?.blob();
        },
        match: (key: string) => {
            return cache.match(key);
        },
        put2: (key: string, blob: Blob) => cache.put(key, new Response(blob)),
        put: (key: string, data: Response) => {
            return cache.put(key, data);
        },
        delete: (key: string) => {
            return cache.delete(key);
        },
    };
};

/** An implementation of {@link BlobCache} using OPFS */
const openOPFSCacheWeb = async (name: BlobCacheNamespace) => {
    // While all major browsers support OPFS now, their implementations still
    // have various quirks. However, we don't need to handle all possible cases
    // and can just instead use the APIs and guarantees Chromium provides since
    // this code will only run in our Electron app (which'll use Chromium as the
    // renderer).
    //
    // So for our purpose, these can serve as the doc for what's available:
    // https://web.dev/articles/origin-private-file-system
    const cache = await caches.open(name);

    const root = await navigator.storage.getDirectory();
    const _caches = await root.getDirectoryHandle("cache", { create: true });
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const _cache = await _caches.getDirectoryHandle(name, { create: true });

    return {
        get: async (key: string) => {
            try {
                const fileHandle = await _cache.getFileHandle(key);
                return await fileHandle.getFile();
            } catch (e) {
                if (e instanceof DOMException && e.name == "NotFoundError")
                    return undefined;
                throw e;
            }
        },
        match: (key: string) => {
            return cache.match(key);
        },
        put2: async (key: string, blob: Blob) => {
            const fileHandle = await _cache.getFileHandle(key, {
                create: true,
            });
            const writable = await fileHandle.createWritable();
            await writable.write(blob);
            await writable.close();
        },
        put: async (key: string, data: Response) => {
            await cache.put(key, data);
        },
        delete: (key: string) => {
            // try {
            //     await _cache.removeEntry(key);
            //     return true;
            // } catch (e) {
            //     if (e instanceof DOMException && e.name == "NotFoundError")
            //         return false;
            //     throw e;
            // }
            return cache.delete(key);
        },
    };
};

export async function cached(
    cacheName: BlobCacheNamespace,
    id: string,
    get: () => Promise<Blob>,
): Promise<Blob> {
    const cache = await openCache(cacheName);
    const cachedBlob = await cache.get(id);
    if (cachedBlob) return cachedBlob;

    const blob = await get();
    await cache.put2(id, blob);
    return blob;
}

/**
 * Delete all cached data.
 *
 * Meant for use during logout, to reset the state of the user's account.
 */
export const clearCaches = async () =>
    isElectron() ? clearOPFSCaches() : clearWebCaches();

export const clearWebCaches = async () => {
    await Promise.all(blobCacheNames.map((name) => caches.delete(name)));
};

export const clearOPFSCaches = async () => {
    const root = await navigator.storage.getDirectory();
    await root.removeEntry("cache", { recursive: true });
};
