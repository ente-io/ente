import log from "@/next/log";
import { CacheStorageFactory } from "./factory";

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
