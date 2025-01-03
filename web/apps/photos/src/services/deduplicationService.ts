import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { EnteFile } from "@/media/file";
import { metadataHash, type Metadata } from "@/media/file-metadata";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";

interface DuplicatesResponse {
    duplicates: {
        fileIDs: number[];
        size: number;
    }[];
}

export interface Duplicate {
    files: EnteFile[];
    size: number;
}

export async function getDuplicates(
    files: EnteFile[],
    collectionNameMap: Map<number, string>,
) {
    try {
        const ascDupes = await fetchDuplicateFileIDs();

        const descSortedDupes = ascDupes.sort((firstDupe, secondDupe) => {
            return secondDupe.size - firstDupe.size;
        });

        const fileMap = new Map<number, EnteFile>();
        for (const file of files) {
            fileMap.set(file.id, file);
        }

        let result: Duplicate[] = [];

        for (const dupe of descSortedDupes) {
            let duplicateFiles: EnteFile[] = [];
            for (const fileID of dupe.fileIDs) {
                if (fileMap.has(fileID)) {
                    duplicateFiles.push(fileMap.get(fileID));
                }
            }
            duplicateFiles = await sortDuplicateFiles(
                duplicateFiles,
                collectionNameMap,
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
        log.error("failed to get duplicate files", e);
    }
}

const hasFileHash = (file: Metadata) => !!metadataHash(file);

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
            }),
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
                hash: metadataHash(file.metadata),
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
                filesSortedByFileHash[i].file.metadata,
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
            await apiURL("/files/duplicates"),
            null,
            {
                "X-Auth-Token": getToken(),
            },
        );
        return (response.data as DuplicatesResponse).duplicates;
    } catch (e) {
        log.error("failed to fetch duplicate file IDs", e);
    }
}

async function sortDuplicateFiles(
    files: EnteFile[],
    collectionNameMap: Map<number, string>,
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
    return metadataHash(firstFile) === metadataHash(secondFile);
}