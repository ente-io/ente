import getFolderSize from "get-folder-size";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { logError } from "../services/logging";

export interface LeastRecentlyUsedResult {
    atime: Date;
    path: string;
}

class DiskLRUService {
    private isRunning: Promise<any> = null;
    private reRun: boolean = false;

    /** Mark "use" of a given file by updating its modified time */
    async markUse(path: string) {
        const now = new Date();
        await fs.utimes(path, now, now);
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
                        try {
                            await fs.unlink(leastRecentlyUsed.path);
                        } catch (e) {
                            // ENOENT: File not found
                            // which can be ignored as we are trying to delete the file anyway
                            if (e.code !== "ENOENT") {
                                logError(
                                    e,
                                    "Failed to evict least recently used",
                                );
                            }
                            // ignoring the error, as it would get retried on the next run
                        }
                        this.evictLeastRecentlyUsed(cacheDir, maxSize);
                    }
                    resolve(null);
                });
            });
        } catch (e) {
            logError(e, "evictLeastRecentlyUsed failed");
        }
    }

    private async findLeastRecentlyUsed(
        dir: string,
        result?: LeastRecentlyUsedResult,
    ): Promise<LeastRecentlyUsedResult> {
        result = result || { atime: new Date(), path: "" };

        const files = await fs.readdir(dir);
        for (const file of files) {
            const newBase = path.join(dir, file);
            const st = await fs.stat(newBase);
            if (st.isDirectory()) {
                result = await this.findLeastRecentlyUsed(newBase, result);
            } else {
                const { atime } = st;
                if (st.atime.getTime() < result.atime.getTime()) {
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
