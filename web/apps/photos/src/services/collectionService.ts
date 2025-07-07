import { sortFiles } from "ente-gallery/utils/file";
import type { EnteFile } from "ente-media/file";
import type {
    CollectionsSortBy,
    CollectionSummary,
} from "ente-new/photos/services/collection-summary";

export const sortCollectionSummaries = (
    collectionSummaries: CollectionSummary[],
    by: CollectionsSortBy,
) =>
    collectionSummaries
        .sort((a, b) => {
            switch (by) {
                case "name":
                    return a.name.localeCompare(b.name);
                case "creation-time-asc":
                    return (
                        -1 *
                        compareCollectionsLatestFile(b.latestFile, a.latestFile)
                    );
                case "updation-time-desc":
                    return (b.updationTime ?? 0) - (a.updationTime ?? 0);
            }
        })
        .sort((a, b) => b.sortPriority - a.sortPriority);

function compareCollectionsLatestFile(
    first: EnteFile | undefined,
    second: EnteFile | undefined,
) {
    if (!first) {
        return 1;
    } else if (!second) {
        return -1;
    } else {
        const sortedFiles = sortFiles([first, second]);
        if (sortedFiles[0].id !== first.id) {
            return 1;
        } else {
            return -1;
        }
    }
}
