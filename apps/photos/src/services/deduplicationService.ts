import { FILE_TYPE } from 'constants/file';
import { EnteFile } from 'types/file';
import { Metadata } from 'types/upload';
import { getEndpoint } from '@ente/shared/network/api';
import { getToken } from '@ente/shared/storage/localStorage/helpers';
import { logError } from '@ente/shared/sentry';
import { hasFileHash } from 'utils/upload';
import HTTPService from '@ente/shared/network/HTTPService';

const ENDPOINT = getEndpoint();

interface DuplicatesResponse {
    duplicates: Array<{
        fileIDs: number[];
        size: number;
    }>;
}

export interface Duplicate {
    files: EnteFile[];
    size: number;
}

export async function getDuplicates(
    files: EnteFile[],
    collectionNameMap: Map<number, string>
) {
    try {
        const dupes = await fetchDuplicateFileIDs();

        const fileMap = new Map<number, EnteFile>();
        for (const file of files) {
            fileMap.set(file.id, file);
        }

        let result: Duplicate[] = [];

        for (const dupe of dupes) {
            let duplicateFiles: EnteFile[] = [];
            for (const fileID of dupe.fileIDs) {
                if (fileMap.has(fileID)) {
                    duplicateFiles.push(fileMap.get(fileID));
                }
            }
            duplicateFiles = await sortDuplicateFiles(
                duplicateFiles,
                collectionNameMap
            );

            if (duplicateFiles.length > 1) {
                result = [
                    ...result,
                    ...getDupesGroupedBySameFileHashes({
                        files: duplicateFiles,
                        size: dupe.size,
                    }),
                ];
            }
        }

        return result;
    } catch (e) {
        logError(e, 'failed to get duplicate files');
    }
}

function getDupesGroupedBySameFileHashes(dupe: Duplicate) {
    const result: Duplicate[] = [];

    const fileWithHashes: EnteFile[] = [];
    const fileWithoutHashes: EnteFile[] = [];
    for (const file of dupe.files) {
        if (hasFileHash(file.metadata)) {
            fileWithHashes.push(file);
        } else {
            fileWithoutHashes.push(file);
        }
    }

    if (fileWithHashes.length > 1) {
        result.push(
            ...groupDupesByFileHashes({
                files: fileWithHashes,
                size: dupe.size,
            })
        );
    }

    if (fileWithoutHashes.length > 1) {
        result.push({
            files: fileWithoutHashes,
            size: dupe.size,
        });
    }
    return result;
}

function groupDupesByFileHashes(dupe: Duplicate) {
    const result: Duplicate[] = [];

    const filesSortedByFileHash = dupe.files
        .map((file) => {
            return {
                file,
                hash:
                    file.metadata.hash ??
                    `${file.metadata.imageHash}_${file.metadata.videoHash}`,
            };
        })
        .sort((firstFile, secondFile) => {
            return firstFile.hash.localeCompare(secondFile.hash);
        });

    let sameHashFiles: EnteFile[] = [];
    sameHashFiles.push(filesSortedByFileHash[0].file);
    for (let i = 1; i < filesSortedByFileHash.length; i++) {
        if (
            areFileHashesSame(
                filesSortedByFileHash[i - 1].file.metadata,
                filesSortedByFileHash[i].file.metadata
            )
        ) {
            sameHashFiles.push(filesSortedByFileHash[i].file);
        } else {
            if (sameHashFiles.length > 1) {
                result.push({
                    files: [...sameHashFiles],
                    size: dupe.size,
                });
            }
            sameHashFiles = [filesSortedByFileHash[i].file];
        }
    }
    if (sameHashFiles.length > 1) {
        result.push({
            files: sameHashFiles,
            size: dupe.size,
        });
    }

    return result;
}

async function fetchDuplicateFileIDs() {
    try {
        const response = await HTTPService.get(
            `${ENDPOINT}/files/duplicates`,
            null,
            {
                'X-Auth-Token': getToken(),
            }
        );
        return (response.data as DuplicatesResponse).duplicates;
    } catch (e) {
        logError(e, 'failed to fetch duplicate file IDs');
    }
}

async function sortDuplicateFiles(
    files: EnteFile[],
    collectionNameMap: Map<number, string>
) {
    return files.sort((firstFile, secondFile) => {
        const firstCollectionName = collectionNameMap
            .get(firstFile.collectionID)
            .toLocaleLowerCase();
        const secondCollectionName = collectionNameMap
            .get(secondFile.collectionID)
            .toLocaleLowerCase();
        return firstCollectionName.localeCompare(secondCollectionName);
    });
}

function areFileHashesSame(firstFile: Metadata, secondFile: Metadata) {
    if (firstFile.fileType === FILE_TYPE.LIVE_PHOTO) {
        return (
            firstFile.imageHash === secondFile.imageHash &&
            firstFile.videoHash === secondFile.videoHash
        );
    } else {
        return firstFile.hash === secondFile.hash;
    }
}
