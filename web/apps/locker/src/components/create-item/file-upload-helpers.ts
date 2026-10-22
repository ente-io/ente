import type { LockerUploadProgress } from "@/services/uploads";
import type { LockerCollection, LockerUploadCandidate } from "@/types";

export const dedupeCollectionNames = (names: string[]) => {
    const seen = new Set<string>();
    return names.filter((name) => {
        const trimmedName = name.trim();
        if (!trimmedName || seen.has(trimmedName)) {
            return false;
        }
        seen.add(trimmedName);
        return true;
    });
};

export type UploadCollectionSelection = number | string;

export const uploadCollectionSelection = (
    name: string,
    collections: Pick<LockerCollection, "id" | "name">[],
): UploadCollectionSelection => {
    const matches = collections.filter(
        (collection) => collection.name === name.trim(),
    );
    return matches.length === 1 ? matches[0]!.id : name.trim();
};

export const addCollectionName = <T extends UploadCollectionSelection>(
    names: T[],
    name: T,
): T[] => [...new Set([...names, name])];

export const toggleCollectionName = (
    names: UploadCollectionSelection[],
    name: UploadCollectionSelection,
) =>
    names.includes(name)
        ? names.filter((candidate) => candidate !== name)
        : addCollectionName(names, name);

export const resolveUploadCollectionIDs = (
    selections: UploadCollectionSelection[],
    createdIDs: Map<string, number>,
): number[] => [
    ...new Set(
        selections.map((selection) => {
            if (typeof selection === "number") return selection;
            const id = createdIDs.get(selection.trim());
            if (id === undefined)
                throw new Error("Upload collection could not be resolved");
            return id;
        }),
    ),
];

const uploadItemKeySuffixByFile = new WeakMap<File, string>();
let uploadItemKeyCounter = 0;

export const uploadQueueItemKey = (item: LockerUploadCandidate) =>
    `${item.relativePath ?? item.file.name}:${item.file.size}:${item.file.lastModified}:${
        uploadItemKeySuffixByFile.get(item.file) ??
        (() => {
            const suffix = String(++uploadItemKeyCounter);
            uploadItemKeySuffixByFile.set(item.file, suffix);
            return suffix;
        })()
    }`;

export const uploadItemParentPath = (item: LockerUploadCandidate) => {
    const segments = (item.relativePath ?? item.file.name)
        .split("/")
        .filter(Boolean);
    return segments.slice(0, -1).join("/");
};

export const collectionsByUploadItem = (
    items: LockerUploadCandidate[],
    defaultCollectionID?: number,
    collections: Pick<LockerCollection, "id" | "name">[] = [],
) =>
    Object.fromEntries(
        items.map((item) => [
            uploadQueueItemKey(item),
            item.suggestedCollectionNames.length > 0
                ? dedupeCollectionNames(item.suggestedCollectionNames).map(
                      (name) => uploadCollectionSelection(name, collections),
                  )
                : defaultCollectionID !== undefined
                  ? [defaultCollectionID]
                  : [],
        ]),
    );

export const filterNonEmptyUploadItems = (items: LockerUploadCandidate[]) =>
    items.filter((item) => item.file.size > 0);

export const uploadProgressValue = (
    progress: LockerUploadProgress | null | undefined,
    uploadCap: number,
) => {
    if (!progress) {
        return 0;
    }

    if (progress.phase === "uploading") {
        return Math.min(
            uploadCap,
            (progress.loaded / Math.max(progress.total, 1)) * uploadCap,
        );
    }

    if (progress.phase === "finalizing") {
        return 99;
    }

    return 0;
};

export const formatFileSize = (bytes: number) => {
    if (bytes < 1024) {
        return `${bytes} B`;
    }
    if (bytes < 1024 * 1024) {
        return `${(bytes / 1024).toFixed(1)} KB`;
    }
    if (bytes < 1024 * 1024 * 1024) {
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
};

export const uploadFileExtension = (name: string) => {
    const dot = name.lastIndexOf(".");
    return dot > 0 ? name.slice(dot) : "";
};

export const renamedUploadFileName = (originalName: string, value: string) => {
    const extension = uploadFileExtension(originalName);
    let name = value.replace(/[/\\]|[^\u0020-\uFFFF]/g, "").trim();
    if (extension && name.toLowerCase().endsWith(extension.toLowerCase())) {
        name = name.slice(0, -extension.length).trim();
    }
    if (!name || name === "." || name === "..") return undefined;
    name += extension;
    return new TextEncoder().encode(name).length <= 255 ? name : undefined;
};

export const fileForUpload = (item: LockerUploadCandidate) =>
    item.uploadName && item.uploadName !== item.file.name
        ? new File([item.file], item.uploadName, {
              type: item.file.type,
              lastModified: item.file.lastModified,
          })
        : item.file;
