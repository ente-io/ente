import { ipcRenderer } from 'electron';
import path from 'path';
import { existsSync, mkdir, rmSync } from 'promise-fs';
import { DiskCache } from '../services/diskCache';

const CACHE_DIR = 'ente';

const getCacheDir = async () => {
    const systemCacheDir = await ipcRenderer.invoke('get-path', 'cache');
    return path.join(systemCacheDir, CACHE_DIR);
};

const getCacheBucketDir = async (cacheName: string) => {
    const cacheDir = await getCacheDir();
    const cacheBucketDir = path.join(cacheDir, cacheName);
    return cacheBucketDir;
};

export async function openDiskCache(cacheName: string) {
    const cacheBucketDir = await getCacheBucketDir(cacheName);
    if (!existsSync(cacheBucketDir)) {
        await mkdir(cacheBucketDir, { recursive: true });
    }
    return new DiskCache(cacheBucketDir);
}

export async function deleteDiskCache(cacheName: string) {
    const cacheBucketDir = await getCacheBucketDir(cacheName);
    if (existsSync(cacheBucketDir)) {
        rmSync(cacheBucketDir, { recursive: true, force: true });
        return true;
    } else {
        return false;
    }
}
