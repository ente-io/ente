import path from 'path';
import { readFile, writeFile, existsSync, unlink } from 'promise-fs';
import DiskLRUService from '../services/diskLRU';
import crypto from 'crypto';

const MAX_CACHE_SIZE = 1000 * 1000 * 1000; // 1GB

export class DiskCache {
    constructor(private cacheBucketDir: string) {}

    async put(cacheKey: string, response: Response): Promise<void> {
        const cachePath = getAssetCachePath(this.cacheBucketDir, cacheKey);
        await writeFile(
            cachePath,
            new Uint8Array(await response.arrayBuffer())
        );
        DiskLRUService.enforceCacheSizeLimit(
            this.cacheBucketDir,
            MAX_CACHE_SIZE
        );
    }

    async match(cacheKey: string): Promise<Response> {
        const cachePath = getAssetCachePath(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            DiskLRUService.touch(cachePath);
            return new Response(await readFile(cachePath));
        } else {
            return undefined;
        }
    }
    async delete(cacheKey: string): Promise<boolean> {
        const cachePath = getAssetCachePath(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            await unlink(cachePath);
            return true;
        } else {
            return false;
        }
    }
}
function getAssetCachePath(cacheDir: string, cacheKey: string) {
    // hashing the key to prevent illegal filenames
    const cacheKeyHash = crypto
        .createHash('sha256')
        .update(cacheKey)
        .digest('hex');
    return path.join(cacheDir, cacheKeyHash);
}
