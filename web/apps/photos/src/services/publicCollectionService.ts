import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { sortFiles } from "ente-gallery/utils/file";
import type { Collection } from "ente-media/collection";
import type { EnteFile, RemoteEnteFile } from "ente-media/file";
import { decryptRemoteFile } from "ente-media/file";
import {
    removePublicCollectionAccessTokenJWT,
    removePublicCollectionByKey,
    removePublicCollectionFiles,
    removePublicCollectionLastSyncTime,
    savedPublicCollectionFiles,
    savedPublicCollectionLastSyncTime,
    savePublicCollectionFiles,
    savePublicCollectionLastSyncTime,
} from "ente-new/albums/services/public-albums-fdb";
import { CustomError, parseSharingErrorCodes } from "ente-shared/error";
import HTTPService from "ente-shared/network/HTTPService";

// Fix this once we can trust the types.
// eslint-disable-next-line @typescript-eslint/no-unnecessary-template-expression
export const getPublicCollectionUID = (token: string) => `${token}`;

export interface LocalSavedPublicCollectionFiles {
    collectionUID: string;
    files: EnteFile[];
}

export const syncPublicFiles = async (
    token: string,
    passwordToken: string,
    collection: Collection,
    setPublicFiles: (files: EnteFile[]) => void,
) => {
    try {
        let files: EnteFile[] = [];
        const sortAsc = collection?.pubMagicMetadata?.data.asc ?? false;
        const collectionUID = getPublicCollectionUID(token);
        const localFiles = await savedPublicCollectionFiles(collectionUID);

        files = [...files, ...localFiles];
        try {
            if (!token) {
                return sortFiles(files, sortAsc);
            }
            const lastSyncTime =
                (await savedPublicCollectionLastSyncTime(collectionUID)) ?? 0;
            if (collection.updationTime === lastSyncTime) {
                return sortFiles(files, sortAsc);
            }
            const fetchedFiles = await getPublicFiles(
                token,
                passwordToken,
                collection,
                lastSyncTime,
                files,
                setPublicFiles,
            );

            files = [...files, ...fetchedFiles];
            const latestVersionFiles = new Map<string, EnteFile>();
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
                // TODO(RE):
                if ("isDeleted" in file && file.isDeleted) {
                    continue;
                }
                files.push(file);
            }
            await savePublicCollectionFiles(collectionUID, files);
            await savePublicCollectionLastSyncTime(
                collectionUID,
                collection.updationTime,
            );
            setPublicFiles([...sortFiles(files, sortAsc)]);
        } catch (e) {
            const parsedError = parseSharingErrorCodes(e);
            log.error("failed to sync shared collection files", e);
            if (parsedError.message === CustomError.TOKEN_EXPIRED) {
                throw e;
            }
        }
        return [...sortFiles(files, sortAsc)];
    } catch (e) {
        log.error("failed to get local  or sync shared collection files", e);
        throw e;
    }
};

const getPublicFiles = async (
    token: string,
    passwordToken: string,
    collection: Collection,
    sinceTime: number,
    files: EnteFile[],
    setPublicFiles: (files: EnteFile[]) => void,
): Promise<EnteFile[]> => {
    try {
        let decryptedFiles: EnteFile[] = [];
        let time = sinceTime;
        let resp;
        const sortAsc = collection?.pubMagicMetadata?.data.asc ?? false;
        do {
            if (!token) {
                break;
            }
            resp = await HTTPService.get(
                await apiURL("/public-collection/diff"),
                { sinceTime: time },
                {
                    "X-Auth-Access-Token": token,
                    ...(passwordToken && {
                        "X-Auth-Access-Token-JWT": passwordToken,
                    }),
                },
            );
            decryptedFiles = [
                ...decryptedFiles,
                ...(await Promise.all(
                    resp.data.diff.map(async (file: RemoteEnteFile) => {
                        if (!file.isDeleted) {
                            return await decryptRemoteFile(
                                file,
                                collection.key,
                            );
                        } else {
                            return file;
                        }
                    }) as Promise<EnteFile>[],
                )),
            ];

            if (resp.data.diff.length) {
                time = resp.data.diff.slice(-1)[0].updationTime;
            }
            setPublicFiles(
                sortFiles(
                    [...(files || []), ...decryptedFiles].filter(
                        // TODO(RE):
                        // (item) => !item.isDeleted,
                        (file) => !("isDeleted" in file && file.isDeleted),
                    ),
                    sortAsc,
                ),
            );
        } while (resp.data.hasMore);
        return decryptedFiles;
    } catch (e) {
        log.error("Get public  files failed", e);
        throw e;
    }
};

export const removePublicCollectionWithFiles = async (
    collectionUID: string,
    collectionKey: string,
) => {
    await removePublicCollectionByKey(collectionKey);
    await removePublicFiles(collectionUID);
};

export const removePublicFiles = async (collectionUID: string) => {
    await removePublicCollectionAccessTokenJWT(collectionUID);
    await removePublicCollectionLastSyncTime(collectionUID);
    await removePublicCollectionFiles(collectionUID);
};
