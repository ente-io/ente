/**
 * @file file system related functions exposed over the context bridge.
 */

import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";

export const fsExists = (path: string) => existsSync(path);

export const fsRename = (oldPath: string, newPath: string) =>
    fs.rename(oldPath, newPath);

export const fsMkdirIfNeeded = (dirPath: string) =>
    fs.mkdir(dirPath, { recursive: true });

export const fsRmdir = (path: string) => fs.rmdir(path);

export const fsRm = (path: string) => fs.rm(path);

export const fsReadTextFile = async (filePath: string) =>
    fs.readFile(filePath, "utf-8");

export const fsWriteFile = (path: string, contents: string) =>
    fs.writeFile(path, contents, { flush: true });

export const fsWriteFileViaBackup = async (path: string, contents: string) => {
    const backupPath = path + ".backup";
    await fs.writeFile(backupPath, contents, { flush: true });
    return fs.rename(backupPath, path);
};

export const fsIsDir = async (dirPath: string) => {
    if (!existsSync(dirPath)) return false;
    const stat = await fs.stat(dirPath);
    return stat.isDirectory();
};

export const fsStatMtime = (path: string) =>
    // [Note: Integral last modified time]
    //
    // Whenever we need to find the modified time of a file, use the
    // `mtime.getTime()` instead of `mtimeMs` of the stat; this way, it is
    // guaranteed that the times are integral (we persist these values to remote
    // in some cases, and the contract is for them to be integral; mtimeMs is a
    // float with sub-millisecond precision), and that all places use the same
    // value so that they're comparable.
    fs.stat(path).then((st) => st.mtime.getTime());

export const fsFindFiles = async (dirPath: string) => {
    const items = await fs.readdir(dirPath, { withFileTypes: true });
    let paths: string[] = [];
    for (const item of items) {
        const itemPath = path.posix.join(dirPath, item.name);
        if (item.isFile()) {
            paths.push(itemPath);
        } else if (item.isDirectory()) {
            paths = [...paths, ...(await fsFindFiles(itemPath))];
        }
    }
    return paths;
};
