import { LRUCache } from "lru-cache";
import StreamZip from "node-stream-zip";

/** The cache. */
const _cache = new LRUCache<string, StreamZip.StreamZipAsync>({
    max: 50,
    disposeAfter: (zip, zipPath) => {
        if (_refCount.has(zipPath)) {
            // Add it back again.
            _cache.set(zipPath, zip);
        } else {
            void zip.close();
        }
    },
});

/** Reference count. */
const _refCount = new Map<string, number>();

/**
 * Cached `StreamZip.async`s
 *
 * This function uses an LRU cache to cache handles to zip files indexed by
 * their path.
 *
 * To clear the cache (which is a good idea to avoid having open file handles
 * lying around), use {@link clearOpenZipCache}.
 *
 * Why was this needed
 * -------------------
 *
 * Caching the StreamZip file handles _significantly_ (hours => seconds)
 * improves the performance of the metadata parsing step during import of large
 * Google Takeout zips.
 *
 * In ad-hoc tests, it seems that beyond a certain zip size (few GBs), reopening
 * the handle to a stream zip overshadows the time taken to read the individual
 * JSONs.
 */
export const openZip = (zipPath: string) => {
    let result = _cache.get(zipPath);
    if (!result) {
        result = new StreamZip.async({ file: zipPath });
        _cache.set(zipPath, result);
    }
    _refCount.set(zipPath, (_refCount.get(zipPath) ?? 0) + 1);
    return result;
};

/**
 * Indicate to our cache that an item we opened earlier using {@link openZip}
 * can now be safely closed.
 *
 * @param zipPath The key that was used for opening this zip.
 */
export const markClosableZip = (zipPath: string) => {
    const rc = _refCount.get(zipPath);
    if (!rc) throw new Error(`Double close for ${zipPath}`);
    if (rc == 1) _refCount.delete(zipPath);
    else _refCount.set(zipPath, rc - 1);
};

/**
 * Clear any entries previously cached by {@link openZip}.
 */
export const clearOpenZipCache = () => {
    if (_refCount.size > 0) {
        const keys = JSON.stringify([..._refCount.keys()]);
        throw new Error(
            `Attempting to clear zip file cache when some items are still in use: ${keys}`,
        );
    }
    _cache.clear();
};
