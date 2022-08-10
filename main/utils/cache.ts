import { ipcRenderer } from 'electron/renderer';
import path from 'path';
import { readFile, writeFile, existsSync, mkdir } from 'promise-fs';
import crypto from 'crypto';
import DiskLRUService from './diskLRU';

const CACHE_DIR = 'ente';
const MAX_CACHE_SIZE = 1000 * 1000 * 1000; // 1GB

const getCacheDir = async () => {
    const systemCacheDir = await ipcRenderer.invoke('get-path', 'cache');
    return path.join(systemCacheDir, CACHE_DIR);
};

export async function openLocalCache(cacheName: string) {
    const cacheDir = await getCacheDir();
    const cacheBucketDir = path.join(cacheDir, cacheName);
    if (!existsSync(cacheBucketDir)) {
        await mkdir(cacheBucketDir, { recursive: true });
    }
    return new DiskCache(cacheBucketDir);
}

class DiskCache {
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
}

function getAssetCachePath(cacheDir: string, cacheKey: string) {
    // hashing the key to prevent illegal filenames
    const cacheKeyHash = crypto
        .createHash('sha256')
        .update(cacheKey)
        .digest('hex');
    return path.join(cacheDir, cacheKeyHash);
}
