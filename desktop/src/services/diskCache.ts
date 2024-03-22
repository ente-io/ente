import { existsSync } from "node:fs";
import * as fs from "node:fs/promises";
import * as path from "node:path";
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
            const fileStats = await fs.stat(cachePath);
            if (sizeInBytes && fileStats.size !== sizeInBytes) {
                logError(
                    Error(),
                    "Cache key exists but size does not match. Deleting cache key.",
                );
                fs.unlink(cachePath).catch((e) => {
                    if (e.code === "ENOENT") return;
                    logError(e, "Failed to delete cache key");
                });
                return undefined;
            }
            DiskLRUService.markUse(cachePath);
            return new Response(await getFileStream(cachePath));
        } else {
            return undefined;
        }
    }
    async delete(cacheKey: string): Promise<boolean> {
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            await fs.unlink(cachePath);
            return true;
        } else {
            return false;
        }
    }
}
