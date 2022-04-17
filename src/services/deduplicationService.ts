import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import { logError } from 'utils/sentry';
import HTTPService from './HTTPService';

const ENDPOINT = getEndpoint();

interface DuplicatesResponse {
    duplicates: Array<{
        fileIDs: number[];
        size: number;
    }>;
}

const DuplicateItemSortingOrderDescBasedOnCollectionName = {
    'icloud library': 0,
    icloudlibrary: 1,
    recents: 2,
    'recently added': 3,
    'my photo stream': 4,
};

const OtherCollectionNameRanking = 5;

interface DuplicateFiles {
    files: EnteFile[];
    size: number;
}

export async function getDuplicateFiles(
    files: EnteFile[],
    collections: Collection[]
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
                collections
            );

            if (duplicateFiles.length > 1) {
                result.push({
                    files: duplicateFiles,
                    size: dupe.size,
                });
            }
        }

        return result;
    } catch (e) {
        logError(e, 'failed to get duplicate files');
    }
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
    collections: Collection[]
) {
    const collectionMap = new Map<number, string>();
    for (const collection of collections) {
        collectionMap.set(collection.id, collection.name);
    }

    return files.sort((firstFile, secondFile) => {
        const firstCollectionName = collectionMap
            .get(firstFile.collectionID)
            .toLocaleLowerCase();
        const secondCollectionName = collectionMap
            .get(secondFile.collectionID)
            .toLocaleLowerCase();
        const firstFileRanking =
            DuplicateItemSortingOrderDescBasedOnCollectionName[
                firstCollectionName
            ] ?? OtherCollectionNameRanking;
        const secondFileRanking =
            DuplicateItemSortingOrderDescBasedOnCollectionName[
                secondCollectionName
            ] ?? OtherCollectionNameRanking;
        return secondFileRanking - firstFileRanking;
    });
}
