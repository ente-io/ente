/**
 * @file file system related functions exposed over the context bridge.
 */
import { existsSync } from "node:fs";
import fs from "node:fs/promises";

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
    fs.writeFile(path, contents);

export const fsIsDir = async (dirPath: string) => {
    if (!existsSync(dirPath)) return false;
    const stat = await fs.stat(dirPath);
    return stat.isDirectory();
};

export const fsLsFiles = async (dirPath: string) =>
    (await fs.readdir(dirPath, { withFileTypes: true }))
        .filter((e) => e.isFile())
        .map((e) => e.name);
