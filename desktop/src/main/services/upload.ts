import fs from "node:fs/promises";
import path from "node:path";
import { existsSync } from "original-fs";
import type { PendingUploads, SkippedFile, ZipItem } from "../../types/ipc";
import log from "../log";
import { uploadStatusStore } from "../stores/upload-status";
import { clearOpenZipCache, markClosableZip, openZip } from "./zip";

// macOS-injected metadata files to tag as `"macosSystemFile"`. Excludes
// plain Unix dotfiles (`.bashrc`, `.config`, ...) which may be legit
// content the user wants backed up. Kept in sync with the web side.
const macosSystemFileBasenames = new Set<string>([
    ".DS_Store",
    ".localized",
    ".Spotlight-V100",
    ".fseventsd",
    ".Trashes",
    ".TemporaryItems",
    ".DocumentRevisions-V100",
]);

export const listZipItems = async (
    zipPath: string,
): Promise<{ items: ZipItem[]; skippedFiles: SkippedFile[] }> => {
    // Filter `._*` forks, other macOS metadata files, and `__MACOSX__`
    // entries into `skippedFiles`. Open failures surface as `"failedZip"`.
    try {
        const zip = openZip(zipPath);
        try {
            const entries = await zip.entries();
            const items: ZipItem[] = [];
            const skippedFiles: SkippedFile[] = [];

            for (const entry of Object.values(entries)) {
                if (!entry.isFile) continue;

                const basename = path.basename(entry.name);
                if (
                    basename.startsWith("._") ||
                    macosSystemFileBasenames.has(basename) ||
                    entry.name.split("/").includes("__MACOSX__")
                ) {
                    skippedFiles.push({
                        name: entry.name,
                        kind: "macosSystemFile",
                    });
                    continue;
                }

                items.push([zipPath, entry.name]);
            }

            return { items, skippedFiles };
        } finally {
            markClosableZip(zipPath);
        }
    } catch (e) {
        log.error("Ignoring malformed zip", e);
        return {
            items: [],
            skippedFiles: [{ name: path.basename(zipPath), kind: "failedZip" }],
        };
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
    let zipItems: ZipItem[] = [];

    // Migration code - May 2024. Remove after a bit (tag: Migration).
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
        const allSkippedFiles: SkippedFile[] = [];
        for (const zip of zipPaths) {
            const result = await listZipItems(zip);
            zipItems = zipItems.concat(result.items);
            allSkippedFiles.push(...result.skippedFiles);
        }

        if (allSkippedFiles.length > 0) {
            uploadStatusStore.set("skippedFiles", allSkippedFiles);
        }
    } else {
        zipItems = allZipItems.filter(([z]) => existsSync(z));
    }

    if (filePaths.length == 0 && zipItems.length == 0) return undefined;

    return {
        collectionName,
        filePaths,
        zipItems,
        skippedFiles: uploadStatusStore.get("skippedFiles") ?? [],
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
    skippedFiles,
}: PendingUploads) => {
    uploadStatusStore.set({
        collectionName: collectionName ?? "",
        filePaths: filePaths,
        zipItems: zipItems,
        skippedFiles: skippedFiles ?? [],
    });
};

export const markUploadedFile = (
    path: string,
    associatedPath: string | undefined,
): Promise<number> => {
    const existing = uploadStatusStore.get("filePaths") ?? [];
    const updated = existing.filter((p) => p != path && p != associatedPath);
    uploadStatusStore.set("filePaths", updated);

    return fs.stat(path).then((st) => st.mtime.getTime());
};

export const markUploadedZipItem = (
    item: ZipItem,
    associatedItem: ZipItem | undefined,
) => {
    const existing = uploadStatusStore.get("zipItems") ?? [];
    const updated = exceptZipItem(
        exceptZipItem(existing, item),
        associatedItem,
    );
    uploadStatusStore.set("zipItems", updated);
    return fs.stat(item[0]).then((st) => st.mtime.getTime());
};

const exceptZipItem = (items: ZipItem[], item: ZipItem | undefined) =>
    item
        ? items.filter((zi) => !(zi[0] == item[0] && zi[1] == item[1]))
        : items;

export const clearPendingUploads = () => {
    uploadStatusStore.clear();
    clearOpenZipCache();
};
