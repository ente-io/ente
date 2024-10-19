//TODO Review entire file
/* eslint-disable @typescript-eslint/no-unnecessary-condition */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { CollectionType, type Collection } from "@/media/collection";
import type { EnteFile } from "@/media/file";
import type { User } from "@ente/shared/user/types";
import { t } from "i18next";
import React, { useReducer } from "react";
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    getDefaultHiddenCollectionIDs,
    HIDDEN_ITEMS_SECTION,
    isDefaultHiddenCollection,
    isIncomingCollabShare,
    isIncomingShare,
    TRASH_SECTION,
} from "../../services/collection";
import type {
    CollectionSummaries,
    CollectionSummary,
    CollectionSummaryType,
} from "../../services/collection/ui";
import { groupFilesBasedOnCollectionID } from "../../services/file";
import {
    isArchivedCollection,
    isArchivedFile,
    isPinnedCollection,
} from "../../services/magic-metadata";
import type { Person } from "../../services/ml/people";

/**
 * Derived UI state backing the gallery.
 *
 * This might be different from the actual different from the actual underlying
 * state since there might be unsynced data (hidden or deleted that have not yet
 * been synced with remote) that should be temporarily taken into account for
 * the UI state until the operation completes.
 */
export interface GalleryState {
    filteredData: EnteFile[];
    /**
     * The currently selected person, if any.
     *
     * Whenever this is present, it is guaranteed to be one of the items from
     * within {@link people}.
     */
    activePerson: Person | undefined;
    /**
     * The list of people to show.
     */
    people: Person[] | undefined;
}

// TODO: dummy actions for gradual migration to reducers
export type GalleryAction =
    | {
          type: "set";
          filteredData: EnteFile[];
          galleryPeopleState:
              | { activePerson: Person | undefined; people: Person[] }
              | undefined;
      }
    | { type: "dummy" };

const initialGalleryState: GalleryState = {
    filteredData: [],
    activePerson: undefined,
    people: [],
};

const galleryReducer: React.Reducer<GalleryState, GalleryAction> = (
    state,
    action,
) => {
    switch (action.type) {
        case "dummy":
            return state;
        case "set":
            return {
                ...state,
                filteredData: action.filteredData,
                activePerson: action.galleryPeopleState?.activePerson,
                people: action.galleryPeopleState?.people,
            };
    }
};

export const useGalleryReducer = () =>
    useReducer(galleryReducer, initialGalleryState);

export const setDerivativeState = (
    user: User,
    collections: Collection[],
    hiddenCollections: Collection[],
    files: EnteFile[],
    trashedFiles: EnteFile[],
    hiddenFiles: EnteFile[],
) => {
    let favItemIds = new Set<number>();
    for (const collection of collections) {
        if (collection.type === CollectionType.favorites) {
            favItemIds = new Set(
                files
                    .filter((file) => file.collectionID === collection.id)
                    .map((file): number => file.id),
            );
            break;
        }
    }
    setFavItemIds(favItemIds);
    const archivedCollections = getArchivedCollections(collections);
    setArchivedCollections(archivedCollections);
    const defaultHiddenCollectionIDs =
        getDefaultHiddenCollectionIDs(hiddenCollections);
    setDefaultHiddenCollectionIDs(defaultHiddenCollectionIDs);
    const hiddenFileIds = new Set<number>(hiddenFiles.map((f) => f.id));
    setHiddenFileIds(hiddenFileIds);
    const collectionSummaries = getCollectionSummaries(
        user,
        collections,
        files,
    );
    const sectionSummaries = getSectionSummaries(
        files,
        trashedFiles,
        archivedCollections,
    );
    const hiddenCollectionSummaries = getCollectionSummaries(
        user,
        hiddenCollections,
        hiddenFiles,
    );
    const hiddenItemsSummaries = getHiddenItemsSummary(
        hiddenFiles,
        hiddenCollections,
    );
    hiddenCollectionSummaries.set(HIDDEN_ITEMS_SECTION, hiddenItemsSummaries);
    setCollectionSummaries(mergeMaps(collectionSummaries, sectionSummaries));
    setHiddenCollectionSummaries(hiddenCollectionSummaries);
};

export function getUniqueFiles(files: EnteFile[]) {
    const idSet = new Set<number>();
    const uniqueFiles = files.filter((file) => {
        if (!idSet.has(file.id)) {
            idSet.add(file.id);
            return true;
        } else {
            return false;
        }
    });

    return uniqueFiles;
}

export const getArchivedCollections = (collections: Collection[]) => {
    return new Set<number>(
        collections
            .filter(isArchivedCollection)
            .map((collection) => collection.id),
    );
};

export function getCollectionSummaries(
    user: User,
    collections: Collection[],
    files: EnteFile[],
): CollectionSummaries {
    const collectionSummaries: CollectionSummaries = new Map();
    const collectionLatestFiles = getCollectionLatestFiles(files);
    const collectionCoverFiles = getCollectionCoverFiles(files, collections);
    const collectionFilesCount = getCollectionsFileCount(files);

    let hasUncategorizedCollection = false;
    for (const collection of collections) {
        if (
            !hasUncategorizedCollection &&
            collection.type === CollectionType.uncategorized
        ) {
            hasUncategorizedCollection = true;
        }
        let type: CollectionSummaryType;
        if (isIncomingShare(collection, user)) {
            if (isIncomingCollabShare(collection, user)) {
                type = "incomingShareCollaborator";
            } else {
                type = "incomingShareViewer";
            }
        } else if (isOutgoingShare(collection, user)) {
            type = "outgoingShare";
        } else if (isSharedOnlyViaLink(collection)) {
            type = "sharedOnlyViaLink";
        } else if (isArchivedCollection(collection)) {
            type = "archived";
        } else if (isDefaultHiddenCollection(collection)) {
            type = "defaultHidden";
        } else if (isPinnedCollection(collection)) {
            type = "pinned";
        } else {
            // Directly use the collection type
            // TODO: The constants can be aligned once collection type goes from
            // an enum to an union.
            switch (collection.type) {
                case CollectionType.folder:
                    type = "folder";
                    break;
                case CollectionType.favorites:
                    type = "favorites";
                    break;
                case CollectionType.album:
                    type = "album";
                    break;
                case CollectionType.uncategorized:
                    type = "uncategorized";
                    break;
            }
        }

        let CollectionSummaryItemName: string;
        if (type == "uncategorized") {
            CollectionSummaryItemName = t("section_uncategorized");
        } else if (type == "favorites") {
            CollectionSummaryItemName = t("favorites");
        } else {
            CollectionSummaryItemName = collection.name;
        }

        collectionSummaries.set(collection.id, {
            id: collection.id,
            name: CollectionSummaryItemName,
            // @ts-expect-error TODO Review types
            latestFile: collectionLatestFiles.get(collection.id),
            coverFile: collectionCoverFiles.get(collection.id),
            fileCount: collectionFilesCount.get(collection.id) ?? 0,
            updationTime: collection.updationTime,
            type: type,
            order: collection.magicMetadata?.data?.order ?? 0,
        });
    }
    if (!hasUncategorizedCollection) {
        collectionSummaries.set(
            DUMMY_UNCATEGORIZED_COLLECTION,
            getDummyUncategorizedCollectionSummary(),
        );
    }

    return collectionSummaries;
}

export type CollectionToFileMap = Map<number, EnteFile>;

export const getCollectionLatestFiles = (
    files: EnteFile[],
): CollectionToFileMap => {
    const latestFiles = new Map<number, EnteFile>();

    files.forEach((file) => {
        if (!latestFiles.has(file.collectionID)) {
            latestFiles.set(file.collectionID, file);
        }
    });
    return latestFiles;
};

export const getCollectionCoverFiles = (
    files: EnteFile[],
    collections: Collection[],
): CollectionToFileMap => {
    const collectionIDToFileMap = groupFilesBasedOnCollectionID(files);

    const coverFiles = new Map<number, EnteFile>();

    collections.forEach((collection) => {
        const collectionFiles = collectionIDToFileMap.get(collection.id);
        if (!collectionFiles || collectionFiles.length === 0) {
            return;
        }
        const coverID = collection.pubMagicMetadata?.data?.coverID;
        if (typeof coverID === "number" && coverID > 0) {
            const coverFile = collectionFiles.find(
                (file) => file.id === coverID,
            );
            if (coverFile) {
                coverFiles.set(collection.id, coverFile);
                return;
            }
        }
        if (collection.pubMagicMetadata?.data?.asc) {
            coverFiles.set(
                collection.id,
                // @ts-expect-error TODO Review types
                collectionFiles[collectionFiles.length - 1],
            );
        } else {
            // @ts-expect-error TODO Review types
            coverFiles.set(collection.id, collectionFiles[0]);
        }
    });
    return coverFiles;
};

export function isOutgoingShare(collection: Collection, user: User): boolean {
    return collection.owner.id === user.id && collection.sharees?.length > 0;
}

export function isSharedOnlyViaLink(collection: Collection) {
    return collection.publicURLs?.length && !collection.sharees?.length;
}

export function getDummyUncategorizedCollectionSummary(): CollectionSummary {
    return {
        id: DUMMY_UNCATEGORIZED_COLLECTION,
        name: t("section_uncategorized"),
        type: "uncategorized",
        // @ts-expect-error TODO Review types
        latestFile: null,
        // @ts-expect-error TODO Review types
        coverFile: null,
        fileCount: 0,
        updationTime: 0,
    };
}

export function getHiddenItemsSummary(
    hiddenFiles: EnteFile[],
    hiddenCollections: Collection[],
): CollectionSummary {
    const defaultHiddenCollectionIds = new Set(
        hiddenCollections
            .filter((collection) => isDefaultHiddenCollection(collection))
            .map((collection) => collection.id),
    );
    const hiddenItems = getUniqueFiles(
        hiddenFiles.filter((file) =>
            defaultHiddenCollectionIds.has(file.collectionID),
        ),
    );
    return {
        id: HIDDEN_ITEMS_SECTION,
        name: t("hidden_items"),
        type: "hiddenItems",
        coverFile: hiddenItems?.[0],
        // @ts-expect-error TODO Review types
        latestFile: hiddenItems?.[0],
        fileCount: hiddenItems?.length,
        // @ts-expect-error TODO Review types
        updationTime: hiddenItems?.[0]?.updationTime,
    };
}

export function getSectionSummaries(
    files: EnteFile[],
    trashedFiles: EnteFile[],
    archivedCollections: Set<number>,
): CollectionSummaries {
    const collectionSummaries: CollectionSummaries = new Map();
    collectionSummaries.set(
        ALL_SECTION,
        getAllSectionSummary(files, archivedCollections),
    );
    collectionSummaries.set(
        TRASH_SECTION,
        getTrashedCollectionSummary(trashedFiles),
    );
    collectionSummaries.set(ARCHIVE_SECTION, getArchivedSectionSummary(files));

    return collectionSummaries;
}

export function getArchivedSectionSummary(
    files: EnteFile[],
): CollectionSummary {
    const archivedFiles = getUniqueFiles(
        files.filter((file) => isArchivedFile(file)),
    );
    return {
        id: ARCHIVE_SECTION,
        name: t("section_archive"),
        type: "archive",
        // @ts-expect-error TODO Review types
        coverFile: null,
        // @ts-expect-error TODO Review types
        latestFile: archivedFiles?.[0],
        fileCount: archivedFiles?.length,
        // @ts-expect-error TODO Review types
        updationTime: archivedFiles?.[0]?.updationTime,
    };
}

function getAllSectionSummary(
    files: EnteFile[],
    archivedCollections: Set<number>,
): CollectionSummary {
    const allSectionFiles = getAllSectionVisibleFiles(
        files,
        archivedCollections,
    );
    return {
        id: ALL_SECTION,
        name: t("section_all"),
        type: "all",
        coverFile: allSectionFiles?.[0],
        // @ts-expect-error TODO Review types
        latestFile: allSectionFiles?.[0],
        fileCount: allSectionFiles?.length || 0,
        // @ts-expect-error TODO Review types
        updationTime: allSectionFiles?.[0]?.updationTime,
    };
}

function getCollectionsFileCount(files: EnteFile[]): Map<number, number> {
    const collectionIDToFileMap = groupFilesBasedOnCollectionID(files);
    const collectionFilesCount = new Map<number, number>();
    for (const [id, files] of collectionIDToFileMap) {
        collectionFilesCount.set(id, files.length);
    }
    return collectionFilesCount;
}

function getAllSectionVisibleFiles(
    files: EnteFile[],
    archivedCollections: Set<number>,
): EnteFile[] {
    const allSectionVisibleFiles = getUniqueFiles(
        files.filter((file) => {
            if (
                isArchivedFile(file) ||
                archivedCollections.has(file.collectionID)
            ) {
                return false;
            }
            return true;
        }),
    );
    return allSectionVisibleFiles;
}

export function getTrashedCollectionSummary(
    trashedFiles: EnteFile[],
): CollectionSummary {
    return {
        id: TRASH_SECTION,
        name: t("section_trash"),
        type: "trash",
        // @ts-expect-error TODO Review types
        coverFile: null,
        // @ts-expect-error TODO Review types
        latestFile: trashedFiles?.[0],
        fileCount: trashedFiles?.length,
        // @ts-expect-error TODO Review types
        updationTime: trashedFiles?.[0]?.updationTime,
    };
}

const mergeMaps = <K, V>(map1: Map<K, V>, map2: Map<K, V>) => {
    const mergedMap = new Map<K, V>(map1);
    map2.forEach((value, key) => {
        mergedMap.set(key, value);
    });
    return mergedMap;
};
