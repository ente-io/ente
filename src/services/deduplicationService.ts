import { FILE_TYPE } from 'constants/file';
import { EnteFile } from 'types/file';
import { Metadata } from 'types/upload';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import { logError } from 'utils/sentry';
import { hasFileHash } from 'utils/upload';
import HTTPService from './HTTPService';

const ENDPOINT = getEndpoint();

interface DuplicatesResponse {
    duplicates: Array<{
        fileIDs: number[];
        size: number;
    }>;
}

interface DuplicateFiles {
    files: EnteFile[];
    size: number;
}

export async function getDuplicateFiles(
    files: EnteFile[],
    collectionNameMap: Map<number, string>
) {
    try {
        const dupes = await fetchDuplicateFileIDs();

        const fileMap = new Map<number, EnteFile>();
        for (const file of files) {
            fileMap.set(file.id, file);
        }

        const result: DuplicateFiles[] = [];

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
                result.push(
                    ...getDupesGroupedBySameFileHashes(
                        duplicateFiles,
                        dupe.size
                    )
                );
            }
        }

        return result;
    } catch (e) {
        logError(e, 'failed to get duplicate files');
    }
}

function getDupesGroupedBySameFileHashes(files: EnteFile[], size: number) {
    const clubbedDupesByFileHash = clubDuplicatesBySameFileHashes([
        { files, size },
    ]);

    const clubbedFileIDs = new Set<number>();
    for (const dupe of clubbedDupesByFileHash) {
        for (const file of dupe.files) {
            clubbedFileIDs.add(file.id);
        }
    }

    files = files.filter((file) => {
        return !clubbedFileIDs.has(file.id);
    });

    if (files.length > 1) {
        clubbedDupesByFileHash.push({
            files: [...files],
            size,
        });
    }

    return clubbedDupesByFileHash;
}

function clubDuplicatesBySameFileHashes(dupes: DuplicateFiles[]) {
    const result: DuplicateFiles[] = [];

    for (const dupe of dupes) {
        let files: EnteFile[] = [];

        const filteredFiles = dupe.files.filter((file) => {
            return hasFileHash(file.metadata);
        });

        if (filteredFiles.length <= 1) {
            continue;
        }

        const dupesSortedByFileHash = filteredFiles
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

        files.push(dupesSortedByFileHash[0].file);
        for (let i = 1; i < dupesSortedByFileHash.length; i++) {
            if (
                areFileHashesSame(
                    dupesSortedByFileHash[i - 1].file.metadata,
                    dupesSortedByFileHash[i].file.metadata
                )
            ) {
                files.push(dupesSortedByFileHash[i].file);
            } else {
                if (files.length > 1) {
                    result.push({
                        files: [...files],
                        size: dupe.size,
                    });
                }
                files = [dupesSortedByFileHash[i].file];
            }
        }

        if (files.length > 1) {
            result.push({
                files,
                size: dupe.size,
            });
        }
    }

    return result;
}

export function clubDuplicatesByTime(dupes: DuplicateFiles[]) {
    const result: DuplicateFiles[] = [];
    for (const dupe of dupes) {
        let files: EnteFile[] = [];
        const creationTimeCounter = new Map<number, number>();

        let mostFreqCreationTime = 0;
        let mostFreqCreationTimeCount = 0;
        for (const file of dupe.files) {
            const creationTime = file.metadata.creationTime;
            if (creationTimeCounter.has(creationTime)) {
                creationTimeCounter.set(
                    creationTime,
                    creationTimeCounter.get(creationTime) + 1
                );
            } else {
                creationTimeCounter.set(creationTime, 1);
            }
            if (
                creationTimeCounter.get(creationTime) >
                mostFreqCreationTimeCount
            ) {
                mostFreqCreationTime = creationTime;
                mostFreqCreationTimeCount =
                    creationTimeCounter.get(creationTime);
            }

            files.push(file);
        }

        files = files.filter((file) => {
            return file.metadata.creationTime === mostFreqCreationTime;
        });

        if (files.length > 1) {
            result.push({
                files,
                size: dupe.size,
            });
        }
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
