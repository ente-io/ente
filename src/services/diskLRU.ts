import path from 'path';
import { readdir, stat, unlink } from 'promise-fs';
import getFolderSize from 'get-folder-size';
import { utimes, close, open } from 'promise-fs';
import { logError } from '../services/logging';

export interface LeastRecentlyUsedResult {
    atime: Date;
    path: string;
}

class DiskLRUService {
    private isRunning: Promise<any> = null;
    private reRun: boolean = false;

    async touch(path: string) {
        try {
            const time = new Date();
            await utimes(path, time, time);
        } catch (err) {
            logError(err, 'utimes method touch failed');
            try {
                await close(await open(path, 'w'));
            } catch (e) {
                logError(e, 'open-close method touch failed');
            }
            // log and ignore
        }
    }

    enforceCacheSizeLimit(cacheDir: string, maxSize: number) {
        if (!this.isRunning) {
            this.isRunning = this.evictLeastRecentlyUsed(cacheDir, maxSize);
            this.isRunning.then(() => {
                this.isRunning = null;
                if (this.reRun) {
                    this.reRun = false;
                    this.enforceCacheSizeLimit(cacheDir, maxSize);
                }
            });
        } else {
            this.reRun = true;
        }
    }

    async evictLeastRecentlyUsed(cacheDir: string, maxSize: number) {
        try {
            await new Promise((resolve) => {
                getFolderSize(cacheDir, async (err, size) => {
                    if (err) {
                        throw err;
                    }
                    if (size >= maxSize) {
                        const leastRecentlyUsed =
                            await this.findLeastRecentlyUsed(cacheDir);

                        await unlink(leastRecentlyUsed.path);
                        this.evictLeastRecentlyUsed(cacheDir, maxSize);
                    }
                    resolve(null);
                });
            });
        } catch (e) {
            logError(e, 'evictLeastRecentlyUsed failed');
        }
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
