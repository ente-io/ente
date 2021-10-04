import { SetFiles } from 'pages/gallery';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import { appendPhotoSwipeProps, decryptFile, sortFiles } from 'utils/file';
import { logError } from 'utils/sentry';
import localForage from 'utils/storage/localForage';
import { Collection, getCollection } from './collectionService';
import { File } from './fileService';
import HTTPService from './HTTPService';

const TRASH = 'file-trash';
const TRASH_TIME = 'trash-time';
const DELETED_COLLECTION = 'deleted-collection';
const SYNC_LIMIT = 1000;

const ENDPOINT = getEndpoint();

export interface TrashItem {
    file: File;
    isDeleted: boolean;
    isRestored: boolean;
    deleteBy: number;
    createdAt: number;
    updatedAt: number;
}
export type Trash = TrashItem[];

export async function getLocalTrash() {
    const trash = (await localForage.getItem<Trash>(TRASH)) || [];
    return trash;
}

export async function getLocalDeletedCollections() {
    const trashedCollections: Array<Collection> =
        (await localForage.getItem<Collection[]>(DELETED_COLLECTION)) || [];
    return trashedCollections;
}

export async function cleanTrashCollections(fileTrash: Trash) {
    const trashedCollections = await getLocalDeletedCollections();
    const neededTrashCollections = new Set<number>(
        fileTrash.map((item) => item.file.collectionID)
    );
    const filterCollections = trashedCollections.filter((item) =>
        neededTrashCollections.has(item.id)
    );
    await localForage.setItem(DELETED_COLLECTION, filterCollections);
}

export async function syncTrash(
    collections: Collection[],
    setFiles: SetFiles
): Promise<Trash> {
    const trash = await getLocalTrash();
    collections = [...collections, ...(await getLocalDeletedCollections())];
    const collectionMap = new Map<number, Collection>(
        collections.map((collection) => [collection.id, collection])
    );
    if (!getToken()) {
        return trash;
    }
    const lastSyncTime = (await localForage.getItem<number>(TRASH_TIME)) ?? 0;

    const updatedTrash = await updateTrash(
        collectionMap,
        lastSyncTime,
        setFiles,
        trash
    );
    cleanTrashCollections(updatedTrash);
}

export const updateTrash = async (
    collections: Map<number, Collection>,
    sinceTime: number,
    setFiles: SetFiles,
    currentTrash: Trash
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
                `${ENDPOINT}/trash/diff`,
                {
                    sinceTime: time,
                    limit: SYNC_LIMIT,
                },
                {
                    'X-Auth-Token': token,
                }
            );
            for (const trashItem of resp.data.diff as TrashItem[]) {
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
                    trashItem.file = await decryptFile(
                        trashItem.file,
                        collection
                    );
                }
                updatedTrash.push(trashItem);
            }

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updatedAt;
            }
            updatedTrash = removeDuplicates(updatedTrash);

            setFiles((files) =>
                sortFiles([...(files ?? []), ...getTrashedFiles(updatedTrash)])
            );
            localForage.setItem(TRASH, updatedTrash);
            localForage.setItem(TRASH_TIME, time);
        } while (resp.data.diff.length === SYNC_LIMIT);
        return updatedTrash;
    } catch (e) {
        logError(e, 'Get trash files failed');
    }
};

function removeDuplicates(trash: Trash) {
    const latestVersionTrashItems = new Map<number, TrashItem>();
    trash.forEach(({ file, updatedAt, ...rest }) => {
        if (
            !latestVersionTrashItems.has(file.id) ||
            latestVersionTrashItems.get(file.id).updatedAt < updatedAt
        ) {
            latestVersionTrashItems.set(file.id, { file, updatedAt, ...rest });
        }
    });
    trash = [];
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    for (const [_, trashedFile] of latestVersionTrashItems) {
        if (trashedFile.isDeleted || trashedFile.isRestored) {
            continue;
        }
        trash.push(trashedFile);
    }
    return trash;
}

export function getTrashedFiles(trash: Trash) {
    return appendPhotoSwipeProps(
        trash.map((trashedFile) => ({
            ...trashedFile.file,
            updationTime: trashedFile.updatedAt,
            isTrashed: true,
            deleteBy: trashedFile.deleteBy,
        }))
    );
}
