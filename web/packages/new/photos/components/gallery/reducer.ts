import {
    COLLECTION_ROLE,
    CollectionType,
    type Collection,
} from "@/media/collection";
import type { EnteFile } from "@/media/file";
import { isHiddenCollection } from "@/new/photos/services/collection";
import { splitByPredicate } from "@/utils/array";
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
import type { FamilyData } from "../../services/user";

/**
 * Derived UI state backing the gallery.
 *
 * This might be different from the actual different from the actual underlying
 * state since there might be unsynced data (hidden or deleted that have not yet
 * been synced with remote) that should be temporarily taken into account for
 * the UI state until the operation completes.
 */
export interface GalleryState {
    /**
     * The logged in {@link User}.
     *
     * This is expected to be undefined only for a brief duration until the code
     * for the initial "mount" runs (If we're not logged in, then the gallery
     * will redirect the user to an appropriate authentication page).
     */
    user: User | undefined;
    /**
     * Family plan related information for the logged in {@link User}.
     */
    familyData: FamilyData | undefined;

    /**
     * The user's non-hidden collections.
     */
    collections: Collection[];
    /**
     * The user's hidden collections.
     */
    hiddenCollections: Collection[];

    filteredData: EnteFile[];
    /**
     * File IDs of all the files that the user has marked as a favorite.
     */
    favFileIDs: Set<number>;
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

export type GalleryAction =
    | {
          type: "mount";
          user: User;
          familyData: FamilyData;
          allCollections: Collection[];
      }
    | {
          type: "set";
          filteredData: EnteFile[];
          galleryPeopleState:
              | { activePerson: Person | undefined; people: Person[] }
              | undefined;
      }
    | { type: "setDerived"; favFileIDs: Set<number> }
    | {
          type: "setNormalCollections";
          collections: Collection[];
      }
    | {
          type: "setAllCollections";
          collections: Collection[];
          hiddenCollections: Collection[];
      }
    | { type: "setFavorites"; favFileIDs: Set<number> };

const initialGalleryState: GalleryState = {
    user: undefined,
    familyData: undefined,
    collections: [],
    hiddenCollections: [],
    filteredData: [],
    favFileIDs: new Set(),
    activePerson: undefined,
    people: [],
};

const galleryReducer: React.Reducer<GalleryState, GalleryAction> = (
    state,
    action,
) => {
    if (process.env.NEXT_PUBLIC_ENTE_WIP_CL) {
        console.log("dispatch", action);
    }
    switch (action.type) {
        case "mount": {
            const [hiddenCollections, collections] = splitByPredicate(
                action.allCollections,
                isHiddenCollection,
            );

            return {
                ...state,
                user: action.user,
                familyData: action.familyData,
                collections: collections,
                hiddenCollections: hiddenCollections,
            };
        }
        case "set":
            return {
                ...state,
                filteredData: action.filteredData,
                activePerson: action.galleryPeopleState?.activePerson,
                people: action.galleryPeopleState?.people,
            };
        case "setDerived":
            return {
                ...state,
                favFileIDs: action.favFileIDs,
            };
        case "setNormalCollections":
            return {
                ...state,
                collections: action.collections,
            };
        case "setAllCollections":
            return {
                ...state,
                collections: action.collections,
                hiddenCollections: action.hiddenCollections,
            };
        case "setFavorites":
            return {
                ...state,
                favFileIDs: action.favFileIDs,
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
    let favFileIDs = new Set<number>();
    for (const collection of collections) {
        if (collection.type === CollectionType.favorites) {
            favFileIDs = new Set(
                files
                    .filter((file) => file.collectionID === collection.id)
                    .map((file): number => file.id),
            );
            break;
        }
    }
    const archivedCollections = getArchivedCollections(collections);
    // TODO: Move to reducer
    // setArchivedCollections(archivedCollections);
    const defaultHiddenCollectionIDs =
        getDefaultHiddenCollectionIDs(hiddenCollections);
    // setDefaultHiddenCollectionIDs(defaultHiddenCollectionIDs);
    const hiddenFileIds = new Set<number>(hiddenFiles.map((f) => f.id));
    // TODO: Move to reducer
    // setHiddenFileIds(hiddenFileIds);
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
    const mergedCollectionSummaries = mergeMaps(
        collectionSummaries,
        sectionSummaries,
    );
    // TODO: Move to reducer
    // setCollectionSummaries(mergeMaps(collectionSummaries, sectionSummaries));
    // TODO: Move to reducer
    // setHiddenCollectionSummaries(hiddenCollectionSummaries);

    return {
        favFileIDs,
        archivedCollections,
        defaultHiddenCollectionIDs,
        hiddenFileIds,
        mergedCollectionSummaries,
        hiddenCollectionSummaries,
    };
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

const getArchivedCollections = (collections: Collection[]) => {
    return new Set<number>(
        collections
            .filter(isArchivedCollection)
            .map((collection) => collection.id),
    );
};

function getCollectionSummaries(
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
            // See: [Note: strict mode migration]
            //
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            latestFile: collectionLatestFiles.get(collection.id),
            coverFile: collectionCoverFiles.get(collection.id),
            fileCount: collectionFilesCount.get(collection.id) ?? 0,
            updationTime: collection.updationTime,
            type: type,
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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

const getCollectionLatestFiles = (files: EnteFile[]): CollectionToFileMap => {
    const latestFiles = new Map<number, EnteFile>();

    files.forEach((file) => {
        if (!latestFiles.has(file.collectionID)) {
            latestFiles.set(file.collectionID, file);
        }
    });
    return latestFiles;
};

const getCollectionCoverFiles = (
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
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (collection.pubMagicMetadata?.data?.asc) {
            coverFiles.set(
                collection.id,
                // See: [Note: strict mode migration]
                //
                // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                // @ts-ignore
                collectionFiles[collectionFiles.length - 1],
            );
        } else {
            // See: [Note: strict mode migration]
            //
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            coverFiles.set(collection.id, collectionFiles[0]);
        }
    });
    return coverFiles;
};

function isIncomingCollabShare(collection: Collection, user: User) {
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    const sharee = collection.sharees?.find((sharee) => sharee.id === user.id);
    return sharee?.role === COLLECTION_ROLE.COLLABORATOR;
}

function isOutgoingShare(collection: Collection, user: User): boolean {
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    return collection.owner.id === user.id && collection.sharees?.length > 0;
}

function isSharedOnlyViaLink(collection: Collection) {
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    return collection.publicURLs?.length && !collection.sharees?.length;
}

function getDummyUncategorizedCollectionSummary(): CollectionSummary {
    return {
        id: DUMMY_UNCATEGORIZED_COLLECTION,
        name: t("section_uncategorized"),
        type: "uncategorized",
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        latestFile: null,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        coverFile: null,
        fileCount: 0,
        updationTime: 0,
    };
}

function getHiddenItemsSummary(
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
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        coverFile: hiddenItems?.[0],
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        latestFile: hiddenItems?.[0],
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        fileCount: hiddenItems?.length,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        updationTime: hiddenItems?.[0]?.updationTime,
    };
}

function getSectionSummaries(
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

function getArchivedSectionSummary(files: EnteFile[]): CollectionSummary {
    const archivedFiles = getUniqueFiles(
        files.filter((file) => isArchivedFile(file)),
    );
    return {
        id: ARCHIVE_SECTION,
        name: t("section_archive"),
        type: "archive",
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        coverFile: null,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        latestFile: archivedFiles?.[0],
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        fileCount: archivedFiles?.length ?? 0,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        coverFile: allSectionFiles?.[0],
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        latestFile: allSectionFiles?.[0],
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        fileCount: allSectionFiles?.length || 0,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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

function getTrashedCollectionSummary(
    trashedFiles: EnteFile[],
): CollectionSummary {
    return {
        id: TRASH_SECTION,
        name: t("section_trash"),
        type: "trash",
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        coverFile: null,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        latestFile: trashedFiles?.[0],
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        fileCount: trashedFiles?.length,
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
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
