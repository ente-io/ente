import StreamZip from "node-stream-zip";
import { existsSync } from "original-fs";
import path from "path";
import type { ElectronFile, PendingUploads, ZipEntry } from "../../types/ipc";
import {
    uploadStatusStore,
    type UploadStatusStore,
} from "../stores/upload-status";
import { getElectronFile, getZipFileStream } from "./fs";

export const zipEntries = async (zipPath: string): Promise<ZipEntry[]> => {
    const zip = new StreamZip.async({ file: zipPath });

    const entries = await zip.entries();
    const entryNames: string[] = [];

    for (const entry of Object.values(entries)) {
        const basename = path.basename(entry.name);
        // Ignore "hidden" files (files whose names begins with a dot).
        if (entry.isFile && basename.length > 0 && basename[0] != ".") {
            // `entry.name` is the path within the zip.
            entryNames.push(entry.name);
        }
    }

    return entryNames.map((entryName) => [zipPath, entryName]);
};

export const pendingUploads = async (): Promise<PendingUploads | undefined> => {
    const collectionName = uploadStatusStore.get("collectionName");
    if (!collectionName) return undefined;

    const allFilePaths = uploadStatusStore.get("filePaths");
    const filePaths = allFilePaths.filter((f) => existsSync(f));

    let allZipEntries = uploadStatusStore.get("zipEntries");
    // Migration code - May 2024. Remove after a bit.
    //
    // The older store formats will not have zipEntries and instead will have
    // zipPaths. If we find such a case, read the zipPaths and enqueue all of
    // their files as zipEntries in the result. This potentially can be cause us
    // to try reuploading an already uploaded file, but the dedup logic will
    // kick in at that point so no harm will come off it.
    if (allZipEntries === undefined) {
        const allZipPaths = uploadStatusStore.get("filePaths");
        const zipPaths = allZipPaths.filter((f) => existsSync(f));
        lsZip();
    }

    if (allZipEntries) "files";
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

export const setPendingUploads = async (pendingUploads: PendingUploads) =>
    uploadStatusStore.set(pendingUploads);

export const markUploadedFiles = async (paths: string[]) => {
    const existing = uploadStatusStore.get("filePaths");
    const updated = existing.filter((p) => !paths.includes(p));
    uploadStatusStore.set("filePaths", updated);
};

export const markUploadedZipEntries = async (
    entries: [zipPath: string, entryName: string][],
) => {
    const existing = uploadStatusStore.get("zipEntries");
    const updated = existing.filter(
        (z) => !entries.some((e) => z[0] == e[0] && z[1] == e[1]),
    );
    uploadStatusStore.set("zipEntries", updated);
};

const validSavedPaths = (type: PendingUploads["type"]) => {
    const key = storeKey(type);
    const savedPaths = (uploadStatusStore.get(key) as string[]) ?? [];
    const paths = savedPaths.filter((p) => existsSync(p));
    uploadStatusStore.set(key, paths);
    return paths;
};

const setPendingUploadCollection = (collectionName: string) => {
    if (collectionName) uploadStatusStore.set("collectionName", collectionName);
    else uploadStatusStore.delete("collectionName");
};

const setPendingUploadFiles = (
    type: PendingUploads["type"],
    filePaths: string[],
) => {
    const key = storeKey(type);
    if (filePaths) uploadStatusStore.set(key, filePaths);
    else uploadStatusStore.delete(key);
};

export const clearPendingUploads = () => uploadStatusStore.clear();

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
