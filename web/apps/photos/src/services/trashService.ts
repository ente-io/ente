import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { apiURL } from "@/next/origins";
import HTTPService from "@ente/shared/network/HTTPService";
import localForage from "@ente/shared/storage/localForage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { Collection } from "types/collection";
import { SetFiles } from "types/gallery";
import { EncryptedTrashItem, Trash } from "types/trash";
import { decryptFile, mergeMetadata, sortTrashFiles } from "utils/file";
import { getCollection } from "./collectionService";

const TRASH = "file-trash";
const TRASH_TIME = "trash-time";
const DELETED_COLLECTION = "deleted-collection";

async function getLocalTrash() {
    const trash = (await localForage.getItem<Trash>(TRASH)) || [];
    return trash;
}

export async function getLocalTrashedFiles() {
    return getTrashedFiles(await getLocalTrash());
}

export async function getLocalDeletedCollections() {
    const trashedCollections: Array<Collection> =
        (await localForage.getItem<Collection[]>(DELETED_COLLECTION)) || [];
    const nonUndefinedCollections = trashedCollections.filter(
        (collection) => !!collection,
    );
    if (nonUndefinedCollections.length !== trashedCollections.length) {
        await localForage.setItem(DELETED_COLLECTION, nonUndefinedCollections);
    }
    return nonUndefinedCollections;
}

export async function cleanTrashCollections(fileTrash: Trash) {
    const trashedCollections = await getLocalDeletedCollections();
    const neededTrashCollections = new Set<number>(
        fileTrash.map((item) => item.file.collectionID),
    );
    const filterCollections = trashedCollections.filter((item) =>
        neededTrashCollections.has(item.id),
    );
    await localForage.setItem(DELETED_COLLECTION, filterCollections);
}

async function getLastSyncTime() {
    return (await localForage.getItem<number>(TRASH_TIME)) ?? 0;
}
export async function syncTrash(
    collections: Collection[],
    setTrashedFiles: SetFiles,
): Promise<void> {
    const trash = await getLocalTrash();
    collections = [...collections, ...(await getLocalDeletedCollections())];
    const collectionMap = new Map<number, Collection>(
        collections.map((collection) => [collection.id, collection]),
    );
    if (!getToken()) {
        return;
    }
    const lastSyncTime = await getLastSyncTime();

    const updatedTrash = await updateTrash(
        collectionMap,
        lastSyncTime,
        setTrashedFiles,
        trash,
    );
    cleanTrashCollections(updatedTrash);
}

export const updateTrash = async (
    collections: Map<number, Collection>,
    sinceTime: number,
    setTrashedFiles: SetFiles,
    currentTrash: Trash,
): Promise<Trash> => {
    try {
        let updatedTrash: Trash = [...currentTrash];
        let time = sinceTime;

        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                await apiURL("/trash/v2/diff"),
                {
                    sinceTime: time,
                },
                {
                    "X-Auth-Token": token,
                },
            );
            // #Perf: This can be optimized by running the decryption in parallel
            for (const trashItem of resp.data.diff as EncryptedTrashItem[]) {
                const collectionID = trashItem.file.collectionID;
                let collection = collections.get(collectionID);
                if (!collection) {
                    collection = await getCollection(collectionID);
                    collections.set(collectionID, collection);
                    localForage.setItem(DELETED_COLLECTION, [
                        ...collections.values(),
                    ]);
                }
                if (!trashItem.isDeleted && !trashItem.isRestored) {
                    const decryptedFile = await decryptFile(
                        trashItem.file,
                        collection.key,
                    );
                    updatedTrash.push({ ...trashItem, file: decryptedFile });
                } else {
                    updatedTrash = updatedTrash.filter(
                        (item) => item.file.id !== trashItem.file.id,
                    );
                }
            }

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updatedAt;
            }

            setTrashedFiles(getTrashedFiles(updatedTrash));
            await localForage.setItem(TRASH, updatedTrash);
            await localForage.setItem(TRASH_TIME, time);
        } while (resp.data.hasMore);
        return updatedTrash;
    } catch (e) {
        log.error("Get trash files failed", e);
    }
    return currentTrash;
};

export function getTrashedFiles(trash: Trash): EnteFile[] {
    return sortTrashFiles(
        mergeMetadata(
            trash.map((trashedFile) => ({
                ...trashedFile.file,
                updationTime: trashedFile.updatedAt,
                deleteBy: trashedFile.deleteBy,
                isTrashed: true,
            })),
        ),
    );
}

export const emptyTrash = async () => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const lastUpdatedAt = await getLastSyncTime();

        await HTTPService.post(
            await apiURL("/trash/empty"),
            { lastUpdatedAt },
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        log.error("empty trash failed", e);
        throw e;
    }
};

export const clearLocalTrash = async () => {
    await localForage.setItem(TRASH, []);
};
