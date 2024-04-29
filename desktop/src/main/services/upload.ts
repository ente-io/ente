import StreamZip from "node-stream-zip";
import { existsSync } from "original-fs";
import path from "path";
import { ElectronFile, type PendingUploads } from "../../types/ipc";
import {
    uploadStatusStore,
    type UploadStatusStore,
} from "../stores/upload-status";
import { getElectronFile, getZipFileStream } from "./fs";

export const lsZip = async (zipPath: string) => {
    const zip = new StreamZip.async({ file: zipPath });

    const entries = await zip.entries();
    const entryPaths: string[] = [];

    for (const entry of Object.values(entries)) {
        const basename = path.basename(entry.name);
        // Ignore "hidden" files (files whose names begins with a dot).
        if (entry.isFile && basename.length > 0 && basename[0] != ".") {
            // `entry.name` is the path within the zip.
            entryPaths.push(entry.name);
        }
    }

    return [entryPaths];
};

export const pendingUploads = async () => {
    const collectionName = uploadStatusStore.get("collectionName");
    const filePaths = validSavedPaths("files");
    const zipPaths = validSavedPaths("zips");

    let files: ElectronFile[] = [];
    let type: PendingUploads["type"];

    if (zipPaths.length) {
        type = "zips";
        for (const zipPath of zipPaths) {
            files = [
                ...files,
                ...(await getElectronFilesFromGoogleZip(zipPath)),
            ];
        }
        const pendingFilePaths = new Set(filePaths);
        files = files.filter((file) => pendingFilePaths.has(file.path));
    } else if (filePaths.length) {
        type = "files";
        files = await Promise.all(filePaths.map(getElectronFile));
    }

    return {
        files,
        collectionName,
        type,
    };
};

export const validSavedPaths = (type: PendingUploads["type"]) => {
    const key = storeKey(type);
    const savedPaths = (uploadStatusStore.get(key) as string[]) ?? [];
    const paths = savedPaths.filter((p) => existsSync(p));
    uploadStatusStore.set(key, paths);
    return paths;
};

export const setPendingUploadCollection = (collectionName: string) => {
    if (collectionName) uploadStatusStore.set("collectionName", collectionName);
    else uploadStatusStore.delete("collectionName");
};

export const setPendingUploadFiles = (
    type: PendingUploads["type"],
    filePaths: string[],
) => {
    const key = storeKey(type);
    if (filePaths) uploadStatusStore.set(key, filePaths);
    else uploadStatusStore.delete(key);
};

export const clearPendingUploads = () => {
    uploadStatusStore.clear();
};

const storeKey = (type: PendingUploads["type"]): keyof UploadStatusStore => {
    switch (type) {
        case "zips":
            return "zipPaths";
        case "files":
            return "filePaths";
    }
};

export const getElectronFilesFromGoogleZip = async (filePath: string) => {
    const zip = new StreamZip.async({
        file: filePath,
    });
    const zipName = path.basename(filePath, ".zip");

    const entries = await zip.entries();
    const files: ElectronFile[] = [];

    for (const entry of Object.values(entries)) {
        const basename = path.basename(entry.name);
        if (entry.isFile && basename.length > 0 && basename[0] !== ".") {
            files.push(await getZipEntryAsElectronFile(zipName, zip, entry));
        }
    }

    return files;
};

export async function getZipEntryAsElectronFile(
    zipName: string,
    zip: StreamZip.StreamZipAsync,
    entry: StreamZip.ZipEntry,
): Promise<ElectronFile> {
    return {
        path: path
            .join(zipName, entry.name)
            .split(path.sep)
            .join(path.posix.sep),
        name: path.basename(entry.name),
        size: entry.size,
        lastModified: entry.time,
        stream: async () => {
            return await getZipFileStream(zip, entry.name);
        },
        blob: async () => {
            const buffer = await zip.entryData(entry.name);
            return new Blob([new Uint8Array(buffer)]);
        },
        arrayBuffer: async () => {
            const buffer = await zip.entryData(entry.name);
            return new Uint8Array(buffer);
        },
    };
}
