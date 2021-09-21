import { getEndpoint } from 'utils/common/apiUtil';
import localForage from 'utils/storage/localForage';

import { getToken } from 'utils/common/key';
import { DataStream, MetadataObject } from './upload/uploadService';
import { Collection } from './collectionService';
import HTTPService from './HTTPService';
import { logError } from 'utils/sentry';
import { decryptFile, sortFiles } from 'utils/file';
import QueueProcessor from './upload/queueProcessor';

const ENDPOINT = getEndpoint();
const DIFF_LIMIT: number = 1000;

const FILES = 'files';

export interface fileAttribute {
    encryptedData?: DataStream | Uint8Array;
    objectKey?: string;
    decryptionHeader: string;
}

export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    LIVE_PHOTO,
    OTHERS,
}

/*  Build error occurred
    ReferenceError: Cannot access 'FILE_TYPE' before initialization
    when it was placed in readFileService
*/
// list of format that were missed by type-detection for some files.
export const FORMAT_MISSED_BY_FILE_TYPE_LIB = [
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpeg' },
    { fileType: FILE_TYPE.IMAGE, exactType: 'jpg' },
    { fileType: FILE_TYPE.VIDEO, exactType: 'webm' },
];

export enum VISIBILITY_STATE {
    VISIBLE,
    ARCHIVED,
}
export interface MagicMetadataProps {
    visibility?: VISIBILITY_STATE;
}
export interface MagicMetadata {
    version: number;
    count: number;
    data: string | MagicMetadataProps;
    header: string;
}
export interface File {
    id: number;
    collectionID: number;
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: MetadataObject;
    magicMetadata: MagicMetadata;
    encryptedKey: string;
    keyDecryptionNonce: string;
    key: string;
    src: string;
    msrc: string;
    html: string;
    w: number;
    h: number;
    isDeleted: boolean;
    dataIndex: number;
    updationTime: number;
}

interface UpdateMagicMetadataRequest {
    metadataList: UpdateMagicMetadata[];
}
interface UpdateMagicMetadata {
    id: number;
    magicMetadata: MagicMetadata;
}

export const NEW_MAGIC_METADATA: MagicMetadata = {
    version: 0,
    data: {},
    header: null,
    count: 0,
};
const PARALLEL_FILE_DECRYPTION = 20;

export const getLocalFiles = async () => {
    const files: Array<File> = (await localForage.getItem<File[]>(FILES)) || [];
    return files;
};

export const syncFiles = async (
    collections: Collection[],
    setFiles: (files: File[]) => void
) => {
    const localFiles = await getLocalFiles();
    let files = await removeDeletedCollectionFiles(collections, localFiles);
    if (files.length !== localFiles.length) {
        await localForage.setItem('files', files);
        setFiles(files);
    }
    for (const collection of collections) {
        if (!getToken()) {
            continue;
        }
        const lastSyncTime =
            (await localForage.getItem<number>(`${collection.id}-time`)) ?? 0;
        if (collection.updationTime === lastSyncTime) {
            continue;
        }
        const fetchedFiles =
            (await getFiles(
                collection,
                lastSyncTime,
                DIFF_LIMIT,
                files,
                setFiles
            )) ?? [];
        files.push(...fetchedFiles);
        const latestVersionFiles = new Map<string, File>();
        files.forEach((file) => {
            const uid = `${file.collectionID}-${file.id}`;
            if (
                !latestVersionFiles.has(uid) ||
                latestVersionFiles.get(uid).updationTime < file.updationTime
            ) {
                latestVersionFiles.set(uid, file);
            }
        });
        files = [];
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        for (const [_, file] of latestVersionFiles) {
            if (file.isDeleted) {
                continue;
            }
            files.push(file);
        }
        files = sortFiles(files);
        await localForage.setItem('files', files);
        await localForage.setItem(
            `${collection.id}-time`,
            collection.updationTime
        );
        setFiles(
            files.map((item) => ({
                ...item,
                w: window.innerWidth,
                h: window.innerHeight,
            }))
        );
    }
    return {
        files: files.map((item) => ({
            ...item,
            w: window.innerWidth,
            h: window.innerHeight,
        })),
    };
};

export const getFiles = async (
    collection: Collection,
    sinceTime: number,
    limit: number,
    files: File[],
    setFiles: (files: File[]) => void
): Promise<File[]> => {
    try {
        const decryptedFiles: File[] = [];
        let time =
            sinceTime ||
            (await localForage.getItem<number>(`${collection.id}-time`)) ||
            0;
        let resp;
        do {
            const token = getToken();
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                `${ENDPOINT}/collections/diff`,
                {
                    collectionID: collection.id,
                    sinceTime: time,
                    limit,
                },
                {
                    'X-Auth-Token': token,
                }
            );
            const fileDecrypter = new QueueProcessor(PARALLEL_FILE_DECRYPTION);
            for (let file of resp.data.diff) {
                if (!file.isDeleted) {
                    file = await fileDecrypter.queueUpRequest(() =>
                        decryptFile(file, collection)
                    ).promise;
                    if (!file) {
                        return;
                    }
                }
                decryptedFiles.push(file);
            }

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            setFiles(
                [...(files || []), ...decryptedFiles]
                    .filter((item) => !item.isDeleted)
                    .sort(
                        (a, b) =>
                            b.metadata.creationTime - a.metadata.creationTime
                    )
            );
        } while (resp.data.diff.length === limit);
        return decryptedFiles;
    } catch (e) {
        logError(e, 'Get files failed');
    }
};

const removeDeletedCollectionFiles = async (
    collections: Collection[],
    files: File[]
) => {
    const syncedCollectionIds = new Set<number>();
    for (const collection of collections) {
        syncedCollectionIds.add(collection.id);
    }
    files = files.filter((file) => syncedCollectionIds.has(file.collectionID));
    return files;
};

export const deleteFiles = async (filesToDelete: number[]) => {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        await HTTPService.post(
            `${ENDPOINT}/files/delete`,
            { fileIDs: filesToDelete },
            null,
            {
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'delete failed');
        throw e;
    }
};

export const updateMagicMetadata = async (files: File[]) => {
    const token = getToken();
    if (!token) {
        return;
    }
    const reqBody: UpdateMagicMetadataRequest = { metadataList: [] };
    for (const file of files) {
        reqBody.metadataList.push({
            id: file.id,
            magicMetadata: file.magicMetadata,
        });
    }
    await HTTPService.put(`${ENDPOINT}/files/magic-metadata`, reqBody, null, {
        'X-Auth-Token': token,
    });
};
