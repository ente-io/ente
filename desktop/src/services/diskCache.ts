import crypto from "crypto";
import path from "path";
import { existsSync, rename, stat, unlink } from "promise-fs";
import DiskLRUService from "../services/diskLRU";
import { LimitedCache } from "../types/cache";
import { getFileStream, writeStream } from "./fs";
import { logError } from "./logging";

const DEFAULT_CACHE_LIMIT = 1000 * 1000 * 1000; // 1GB

export class DiskCache implements LimitedCache {
    constructor(
        private cacheBucketDir: string,
        private cacheLimit = DEFAULT_CACHE_LIMIT,
    ) {}

    async put(cacheKey: string, response: Response): Promise<void> {
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        await writeStream(cachePath, response.body);
        DiskLRUService.enforceCacheSizeLimit(
            this.cacheBucketDir,
            this.cacheLimit,
        );
    }

    async match(
        cacheKey: string,
        { sizeInBytes }: { sizeInBytes?: number } = {},
    ): Promise<Response> {
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            const fileStats = await stat(cachePath);
            if (sizeInBytes && fileStats.size !== sizeInBytes) {
                logError(
                    Error(),
                    "Cache key exists but size does not match. Deleting cache key.",
                );
                unlink(cachePath).catch((e) => {
                    if (e.code === "ENOENT") return;
                    logError(e, "Failed to delete cache key");
                });
                return undefined;
            }
            DiskLRUService.touch(cachePath);
            return new Response(await getFileStream(cachePath));
        } else {
            // add fallback for old cache keys
            const oldCachePath = getOldAssetCachePath(
                this.cacheBucketDir,
                cacheKey,
            );
            if (existsSync(oldCachePath)) {
                const fileStats = await stat(oldCachePath);
                if (sizeInBytes && fileStats.size !== sizeInBytes) {
                    logError(
                        Error(),
                        "Old cache key exists but size does not match. Deleting cache key.",
                    );
                    unlink(oldCachePath).catch((e) => {
                        if (e.code === "ENOENT") return;
                        logError(e, "Failed to delete cache key");
                    });
                    return undefined;
                }
                const match = new Response(await getFileStream(oldCachePath));
                void migrateOldCacheKey(oldCachePath, cachePath);
                return match;
            }
            return undefined;
        }
    }
    async delete(cacheKey: string): Promise<boolean> {
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            await unlink(cachePath);
            return true;
        } else {
            return false;
        }
    }
}

function getOldAssetCachePath(cacheDir: string, cacheKey: string) {
    // hashing the key to prevent illegal filenames
    const cacheKeyHash = crypto
        .createHash("sha256")
        .update(cacheKey)
        .digest("hex");
    return path.join(cacheDir, cacheKeyHash);
}

async function migrateOldCacheKey(oldCacheKey: string, newCacheKey: string) {
    try {
        await rename(oldCacheKey, newCacheKey);
    } catch (e) {
        logError(e, "Failed to move cache key to new cache key");
    }
}
