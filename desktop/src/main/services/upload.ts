import fs from "node:fs/promises";
import path from "node:path";
import { existsSync } from "original-fs";
import type { PendingUploads, ZipItem } from "../../types/ipc";
import log from "../log";
import { uploadStatusStore } from "../stores/upload-status";
import { clearOpenZipCache, markClosableZip, openZip } from "./zip";

export const listZipItems = async (zipPath: string): Promise<ZipItem[]> => {
    const zip = openZip(zipPath);

    try {
        const entries = await zip.entries();
        const entryNames: string[] = [];

        for (const entry of Object.values(entries)) {
            const basename = path.basename(entry.name);
            // Ignore "hidden" files (files whose names begins with a dot).
            if (entry.isFile && !basename.startsWith(".")) {
                // `entry.name` is the path within the zip.
                entryNames.push(entry.name);
            }
        }
        return entryNames.map((entryName) => [zipPath, entryName]);
    } finally {
        markClosableZip(zipPath);
    }
};

export const pathOrZipItemSize = async (
    pathOrZipItem: string | ZipItem,
): Promise<number> => {
    if (typeof pathOrZipItem == "string") {
        const stat = await fs.stat(pathOrZipItem);
        return stat.size;
    } else {
        const [zipPath, entryName] = pathOrZipItem;
        const zip = openZip(zipPath);
        try {
            const entry = await zip.entry(entryName);
            if (!entry)
                throw new Error(
                    `An entry with name ${entryName} does not exist in the zip file at ${zipPath}`,
                );
            return entry.size;
        } finally {
            markClosableZip(zipPath);
        }
    }
};

export const pendingUploads = async (): Promise<PendingUploads | undefined> => {
    const collectionName = uploadStatusStore.get("collectionName") ?? undefined;

    const allFilePaths = uploadStatusStore.get("filePaths") ?? [];
    const filePaths = allFilePaths.filter((f) => existsSync(f));

    const allZipItems = uploadStatusStore.get("zipItems");
    let zipItems: typeof allZipItems;

    // Migration code - May 2024. Remove after a bit.
    //
    // The older store formats will not have zipItems and instead will have
    // zipPaths. If we find such a case, read the zipPaths and enqueue all of
    // their files as zipItems in the result.
    //
    // This potentially can be cause us to try reuploading an already uploaded
    // file, but the dedup logic will kick in at that point so no harm will come
    // of it.
    if (allZipItems === undefined) {
        const allZipPaths = uploadStatusStore.get("zipPaths") ?? [];
        const zipPaths = allZipPaths.filter((f) => existsSync(f));
        zipItems = [];
        for (const zip of zipPaths) {
            try {
                zipItems = zipItems.concat(await listZipItems(zip));
            } catch (e) {
                log.error("Ignoring items in malformed zip", e);
            }
        }
    } else {
        zipItems = allZipItems.filter(([z]) => existsSync(z));
    }

    if (filePaths.length == 0 && zipItems.length == 0) return undefined;

    return {
        collectionName,
        filePaths,
        zipItems,
    };
};

/**
 * [Note: Missing values in electron-store]
 *
 * Suppose we were to create a store like this:
 *
 *     const store = new Store({
 *         schema: {
 *             foo: { type: "string" },
 *             bars: { type: "array", items: { type: "string" } },
 *         },
 *     });
 *
 * If we fetch `store.get("foo")` or `store.get("bars")`, we get `undefined`.
 * But if we try to set these back to `undefined`, say `store.set("foo",
 * someUndefValue)`, we get asked to
 *
 *     TypeError: Use `delete()` to clear values
 *
 * This happens even if we do bulk object updates, e.g. with a JS object that
 * has undefined keys:
 *
 * > TypeError: Setting a value of type `undefined` for key `collectionName` is
 * > not allowed as it's not supported by JSON
 *
 * So what should the TypeScript type for "foo" be?
 *
 * If it is were to not include the possibility of `undefined`, then the type
 * would lie because `store.get("foo")` can indeed be `undefined. But if we were
 * to include the possibility of `undefined`, then trying to `store.set("foo",
 * someUndefValue)` will throw.
 *
 * The approach we take is to rely on false-y values (empty strings and empty
 * arrays) to indicate missing values, and then converting those to `undefined`
 * when reading from the store, and converting `undefined` to the corresponding
 * false-y value when writing.
 */
export const setPendingUploads = ({
    collectionName,
    filePaths,
    zipItems,
}: PendingUploads) => {
    uploadStatusStore.set({
        collectionName: collectionName ?? "",
        filePaths: filePaths,
        zipItems: zipItems,
    });
};

export const markUploadedFiles = (paths: string[]) => {
    const existing = uploadStatusStore.get("filePaths") ?? [];
    const updated = existing.filter((p) => !paths.includes(p));
    uploadStatusStore.set("filePaths", updated);
};

export const markUploadedZipItems = (
    items: [zipPath: string, entryName: string][],
) => {
    const existing = uploadStatusStore.get("zipItems") ?? [];
    const updated = existing.filter(
        (z) => !items.some((e) => z[0] == e[0] && z[1] == e[1]),
    );
    uploadStatusStore.set("zipItems", updated);
};

export const clearPendingUploads = () => {
    uploadStatusStore.clear();
    clearOpenZipCache();
};
