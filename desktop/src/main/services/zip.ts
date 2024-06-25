import { LRUCache } from "lru-cache";
import StreamZip from "node-stream-zip";

const _cache = new LRUCache<string, StreamZip.StreamZipAsync>({ max: 50 });

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
    return result;
};

/**
 * Clear any entries previously cached by {@link openZip}.
 */
export const clearOpenZipCache = () => _cache.clear();
