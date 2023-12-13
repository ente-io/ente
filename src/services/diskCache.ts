import DiskLRUService from '../services/diskLRU';
import crypto from 'crypto';
import { existsSync, readFile, unlink } from 'promise-fs';
import path from 'path';
import { LimitedCache } from '../types/cache';
import { logError } from './logging';
import { writeStream } from './fs';

const DEFAULT_CACHE_LIMIT = 1000 * 1000 * 1000; // 1GB

export class DiskCache implements LimitedCache {
    constructor(
        private cacheBucketDir: string,
        private cacheLimit = DEFAULT_CACHE_LIMIT
    ) {}

    async put(cacheKey: string, response: Response): Promise<void> {
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        await writeStream(cachePath, response.body);
        DiskLRUService.enforceCacheSizeLimit(
            this.cacheBucketDir,
            this.cacheLimit
        );
    }

    async match(cacheKey: string): Promise<Response> {
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            DiskLRUService.touch(cachePath);
            return new Response(await readFile(cachePath));
        } else {
            // add fallback for old cache keys
            const oldCachePath = getOldAssetCachePath(
                this.cacheBucketDir,
                cacheKey
            );
            if (existsSync(oldCachePath)) {
                const match = new Response(await readFile(oldCachePath));
                void migrateOldCacheKey(oldCachePath, cachePath, match);
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
        .createHash('sha256')
        .update(cacheKey)
        .digest('hex');
    return path.join(cacheDir, cacheKeyHash);
}

async function migrateOldCacheKey(
    oldCacheKey: string,
    newCacheKey: string,
    value: Response
) {
    try {
        await this.put(newCacheKey, value);
        await this.delete(oldCacheKey);
    } catch (e) {
        logError(e, 'Failed to move cache key to new cache key');
    }
}
