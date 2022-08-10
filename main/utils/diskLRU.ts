import path from 'path';
import { readdir, stat, unlink } from 'promise-fs';
import getFolderSize from 'get-folder-size';
import { utimes, close, open } from 'promise-fs';

export interface LeastRecentlyUsedResult {
    atime: Date;
    path: string;
}

class DiskLRUService {
    async touch(path: string) {
        const time = new Date();
        try {
            await utimes(path, time, time);
        } catch (err) {
            await close(await open(path, 'w'));
        }
    }
    async evictLeastRecentlyUsed(cacheDir: string, maxSize: number) {
        await new Promise((resolve) => {
            getFolderSize(cacheDir, async (err, size) => {
                if (err) {
                    throw err;
                }
                if (size >= maxSize) {
                    const leastRecentlyUsed = await this.findLeastRecentlyUsed(
                        cacheDir
                    );
                    console.log(leastRecentlyUsed);

                    await unlink(leastRecentlyUsed.path);
                    this.evictLeastRecentlyUsed(cacheDir, maxSize);
                }
                resolve(null);
            });
        });
    }

    private async findLeastRecentlyUsed(
        dir: string,
        result?: LeastRecentlyUsedResult
    ): Promise<LeastRecentlyUsedResult> {
        result = result || { atime: new Date(), path: '' };

        const files = await readdir(dir);
        for (const file of files) {
            const newBase = path.join(dir, file);
            const stats = await stat(newBase);
            if (stats.isDirectory()) {
                result = await this.findLeastRecentlyUsed(newBase, result);
            } else {
                const { atime } = await stat(newBase);

                if (atime.getTime() < result.atime.getTime()) {
                    result = {
                        atime,
                        path: newBase,
                    };
                }
            }
        }
        return result;
    }
}

export default new DiskLRUService();
