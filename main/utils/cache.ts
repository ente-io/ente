import { ipcRenderer } from 'electron/renderer';
import path from 'path';
import { readFile, writeFile, existsSync, mkdir } from 'promise-fs';

const getCacheDir = async () => await ipcRenderer.invoke('get-path', 'cache');

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
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        await writeFile(
            cachePath,
            new Uint8Array(await response.arrayBuffer())
        );
    }

    async match(cacheKey: string): Promise<Response> {
        const cachePath = path.join(this.cacheBucketDir, cacheKey);
        if (existsSync(cachePath)) {
            return new Response(await readFile(cachePath));
        } else {
            return undefined;
        }
    }
}
