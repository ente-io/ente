import { ipcRenderer } from "electron/renderer";
import path from "path";
import { existsSync, mkdir, rmSync } from "promise-fs";
import { DiskCache } from "../services/diskCache";

const ENTE_CACHE_DIR_NAME = "ente";

const getCacheDirectory = async () => {
    const defaultSystemCacheDir = await ipcRenderer.invoke("get-path", "cache");
    return path.join(defaultSystemCacheDir, ENTE_CACHE_DIR_NAME);
};

const getCacheBucketDir = async (cacheName: string) => {
    const cacheDir = await getCacheDirectory();
    const cacheBucketDir = path.join(cacheDir, cacheName);
    return cacheBucketDir;
};

export async function openDiskCache(
    cacheName: string,
    cacheLimitInBytes?: number,
) {
    const cacheBucketDir = await getCacheBucketDir(cacheName);
    if (!existsSync(cacheBucketDir)) {
        await mkdir(cacheBucketDir, { recursive: true });
    }
    return new DiskCache(cacheBucketDir, cacheLimitInBytes);
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
