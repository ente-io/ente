import { EnteFile } from 'types/file';
import { getEndpoint } from 'utils/common/apiUtil';
import { getToken } from 'utils/common/key';
import { logError } from 'utils/sentry';
import { getLocalFiles } from './fileService';
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

export async function getDuplicateFiles() {
    try {
        const dupes = await fetchDuplicateFileIDs();

        const localFiles = await getLocalFiles();
        const fileMap = new Map<number, EnteFile>();
        for (const file of localFiles) {
            fileMap.set(file.id, file);
        }

        const result: DuplicateFiles[] = [];

        for (const dupe of dupes) {
            const files: EnteFile[] = [];
            for (const fileID of dupe.fileIDs) {
                if (fileMap.has(fileID)) {
                    files.push(fileMap.get(fileID));
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
