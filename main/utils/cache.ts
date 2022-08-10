import { ipcRenderer } from 'electron/renderer';
import path from 'path';
import {
    readFile,
    writeFile,
    existsSync,
    mkdir,
    readdir,
    stat,
    utimes,
    close,
    open,
    unlink,
    rmdir,
} from 'promise-fs';
import getFolderSize from 'get-folder-size';
import crypto from 'crypto';

interface LeastRecentlyUsedResult {
    atime: Date;
    path: string;
}

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
        const cachePath = makeAssetCachePath(this.cacheBucketDir, cacheKey);
        evictLeastRecentlyUsed(this.cacheBucketDir, MAX_CACHE_SIZE);
        await writeFile(
            cachePath,
            new Uint8Array(await response.arrayBuffer())
        );
    }

    async match(cacheKey: string): Promise<Response> {
        const cachePath = makeAssetCachePath(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            touch(cachePath);
            return new Response(await readFile(cachePath));
        } else {
            return undefined;
        }
    }
}

function makeAssetCachePath(cacheDir: string, cacheKey: string) {
    // hashing the key to prevent illegal filenames
    const cacheKeyHash = crypto
        .createHash('sha256')
        .update(cacheKey)
        .digest('hex');
    return path.join(cacheDir, cacheKeyHash);
}

async function touch(path: string) {
    const time = new Date();
    try {
        await utimes(path, time, time);
    } catch (err) {
        await close(await open(path, 'w'));
    }
}

async function evictLeastRecentlyUsed(cacheDir: string, maxSize: number) {
    const folderSizeInfo = await getFolderSize(cacheDir);
    if (folderSizeInfo.errors) {
        throw folderSizeInfo.errors;
    }
    if (folderSizeInfo.size >= maxSize) {
        // find least recently used file
        const leastRecentlyUsed = await findLeastRecentlyUsed(cacheDir);
        // and delete it
        const { dir } = path.parse(leastRecentlyUsed.path);
        await unlink(leastRecentlyUsed.path);
        await rmdir(dir);
        evictLeastRecentlyUsed(cacheDir, maxSize);
    }
}

async function findLeastRecentlyUsed(
    dir: string,
    result?: LeastRecentlyUsedResult
): Promise<LeastRecentlyUsedResult> {
    const files = await readdir(dir);
    result = result || { atime: new Date(), path: '' };

    files.forEach(async (file) => {
        const newBase = path.join(dir, file);
        const stats = await stat(newBase);
        if (stats.isDirectory()) {
            result = await findLeastRecentlyUsed(newBase, result);
        } else {
            const { atime } = await stat(newBase);

            if (atime < result.atime) {
                result = {
                    atime,
                    path: newBase,
                };
            }
        }
    });

    return result;
}
