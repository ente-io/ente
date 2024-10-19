import {
    COLLECTION_ROLE,
    CollectionType,
    type Collection,
} from "@/media/collection";
import type { EnteFile } from "@/media/file";
import { mergeMetadata } from "@/media/file";
import { isHiddenCollection } from "@/new/photos/services/collection";
import { splitByPredicate } from "@/utils/array";
import { ensure } from "@/utils/ensure";
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
import {
    getLatestVersionFiles,
    groupFilesBasedOnCollectionID,
} from "../../services/file";
import { sortFiles } from "../../services/files";
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
    /*--<  Mostly static state  >--*/

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

    /*--<  Primary state: Files and collections  >--*/

    /**
     * The user's non-hidden collections.
     */
    collections: Collection[];
    /**
     * The user's hidden collections.
     */
    hiddenCollections: Collection[];
    /**
     * The user's normal (non-hidden, non-trash) files.
     */
    files: EnteFile[];
    /**
     * The user's hidden files.
     */
    hiddenFiles: EnteFile[];
    /**
     * The user's files that are in Trash.
     */
    trashedFiles: EnteFile[];

    /*--<  Derived state  >--*/

    /**
     * Collection IDs of archived collections.
     */
    archivedCollectionIDs: Set<number>;
    /**
     * Collection IDs of default hidden collections.
     */
    defaultHiddenCollectionIDs: Set<number>;
    /**
     * File IDs of the files that the user has hidden.
     */
    hiddenFileIDs: Set<number>;
    /**
     * File IDs of all the files that the user has marked as a favorite.
     */
    favoriteFileIDs: Set<number>;

    /*--<  Derived UI state  >--*/

    /**
     * A map of massaged collections suitable for being directly consumed by the
     * UI (indexed by the collection IDs).
     */
    collectionSummaries: Map<number, CollectionSummary>;
    /**
     * A version of {@link collectionSummaries} but for hidden collections.
     */
    hiddenCollectionSummaries: Map<number, CollectionSummary>;

    /*--<  Transient UI state  >--*/

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

export type GalleryAction =
    | {
          type: "mount";
          user: User;
          familyData: FamilyData;
          allCollections: Collection[];
          files: EnteFile[];
          hiddenFiles: EnteFile[];
          trashedFiles: EnteFile[];
      }
    | {
          type: "set";
          filteredData: EnteFile[];
          galleryPeopleState:
              | { activePerson: Person | undefined; people: Person[] }
              | undefined;
      }
    | {
          type: "setNormalCollections";
          collections: Collection[];
      }
    | {
          type: "setAllCollections";
          collections: Collection[];
          hiddenCollections: Collection[];
      }
    | { type: "resetFiles"; files: EnteFile[] }
    | { type: "fetchFiles"; files: EnteFile[] }
    | { type: "uploadFile"; file: EnteFile }
    | { type: "resetHiddenFiles"; hiddenFiles: EnteFile[] }
    | { type: "fetchHiddenFiles"; hiddenFiles: EnteFile[] }
    | { type: "setTrashedFiles"; trashedFiles: EnteFile[] };

const initialGalleryState: GalleryState = {
    user: undefined,
    familyData: undefined,
    collections: [],
    hiddenCollections: [],
    files: [],
    hiddenFiles: [],
    trashedFiles: [],
    archivedCollectionIDs: new Set(),
    defaultHiddenCollectionIDs: new Set(),
    hiddenFileIDs: new Set(),
    favoriteFileIDs: new Set(),
    collectionSummaries: new Map(),
    hiddenCollectionSummaries: new Map(),
    filteredData: [],
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
            const archivedCollectionIDs =
                deriveArchivedCollectionIDs(collections);
            return {
                ...state,
                user: action.user,
                familyData: action.familyData,
                collections: collections,
                hiddenCollections: hiddenCollections,
                files: action.files,
                hiddenFiles: action.hiddenFiles,
                trashedFiles: action.trashedFiles,
                archivedCollectionIDs,
                defaultHiddenCollectionIDs:
                    deriveDefaultHiddenCollectionIDs(hiddenCollections),
                hiddenFileIDs: deriveHiddenFileIDs(action.hiddenFiles),
                favoriteFileIDs: deriveFavoriteFileIDs(
                    collections,
                    action.files,
                ),
                collectionSummaries: deriveCollectionSummaries(
                    action.user,
                    collections,
                    action.files,
                    action.trashedFiles,
                    archivedCollectionIDs,
                ),
                hiddenCollectionSummaries: deriveHiddenCollectionSummaries(
                    action.user,
                    hiddenCollections,
                    action.hiddenFiles,
                ),
            };
        }
        case "set":
            return {
                ...state,
                filteredData: action.filteredData,
                activePerson: action.galleryPeopleState?.activePerson,
                people: action.galleryPeopleState?.people,
            };
        case "setNormalCollections": {
            const archivedCollectionIDs = deriveArchivedCollectionIDs(
                action.collections,
            );
            return {
                ...state,
                collections: action.collections,
                archivedCollectionIDs,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    action.collections,
                    state.files,
                ),
                collectionSummaries: deriveCollectionSummaries(
                    ensure(state.user),
                    action.collections,
                    state.files,
                    state.trashedFiles,
                    archivedCollectionIDs,
                ),
            };
        }
        case "setAllCollections": {
            const archivedCollectionIDs = deriveArchivedCollectionIDs(
                action.collections,
            );
            return {
                ...state,
                collections: action.collections,
                hiddenCollections: action.hiddenCollections,
                archivedCollectionIDs,
                defaultHiddenCollectionIDs: deriveDefaultHiddenCollectionIDs(
                    action.hiddenCollections,
                ),
                favoriteFileIDs: deriveFavoriteFileIDs(
                    action.collections,
                    state.files,
                ),
                collectionSummaries: deriveCollectionSummaries(
                    ensure(state.user),
                    action.collections,
                    state.files,
                    state.trashedFiles,
                    archivedCollectionIDs,
                ),
                hiddenCollectionSummaries: deriveHiddenCollectionSummaries(
                    ensure(state.user),
                    action.hiddenCollections,
                    state.hiddenFiles,
                ),
            };
        }
        case "resetFiles": {
            const files = sortFiles(mergeMetadata(action.files));
            return {
                ...state,
                files,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    state.collections,
                    files,
                ),
                collectionSummaries: deriveCollectionSummaries(
                    ensure(state.user),
                    state.collections,
                    files,
                    state.trashedFiles,
                    state.archivedCollectionIDs,
                ),
            };
        }
        case "fetchFiles": {
            const files = sortFiles(
                mergeMetadata(
                    getLatestVersionFiles([...state.files, ...action.files]),
                ),
            );
            return {
                ...state,
                files,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    state.collections,
                    files,
                ),
                collectionSummaries: deriveCollectionSummaries(
                    ensure(state.user),
                    state.collections,
                    files,
                    state.trashedFiles,
                    state.archivedCollectionIDs,
                ),
            };
        }
        case "uploadFile": {
            const files = sortFiles([...state.files, action.file]);
            return {
                ...state,
                files,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    state.collections,
                    files,
                ),
                // TODO: Consider batching this instead of doing it per file
                // upload to speed up uploads. Perf test first though.
                collectionSummaries: deriveCollectionSummaries(
                    ensure(state.user),
                    state.collections,
                    files,
                    state.trashedFiles,
                    state.archivedCollectionIDs,
                ),
            };
        }
        case "resetHiddenFiles": {
            const hiddenFiles = sortFiles(mergeMetadata(action.hiddenFiles));
            return {
                ...state,
                hiddenFiles,
                hiddenFileIDs: deriveHiddenFileIDs(hiddenFiles),
                hiddenCollectionSummaries: deriveHiddenCollectionSummaries(
                    ensure(state.user),
                    state.hiddenCollections,
                    hiddenFiles,
                ),
            };
        }
        case "fetchHiddenFiles": {
            const hiddenFiles = sortFiles(
                mergeMetadata(
                    getLatestVersionFiles([
                        ...state.hiddenFiles,
                        ...action.hiddenFiles,
                    ]),
                ),
            );
            return {
                ...state,
                hiddenFiles,
                hiddenFileIDs: deriveHiddenFileIDs(hiddenFiles),
                hiddenCollectionSummaries: deriveHiddenCollectionSummaries(
                    ensure(state.user),
                    state.hiddenCollections,
                    hiddenFiles,
                ),
            };
        }
        case "setTrashedFiles":
            return {
                ...state,
                trashedFiles: action.trashedFiles,
                collectionSummaries: deriveCollectionSummaries(
                    ensure(state.user),
                    state.collections,
                    state.files,
                    action.trashedFiles,
                    state.archivedCollectionIDs,
                ),
            };
    }
};

export const useGalleryReducer = () =>
    useReducer(galleryReducer, initialGalleryState);

/**
 * File IDs themselves are unique across all the files for the user (in fact,
 * they're unique across all the files in an Ente instance). However, we still
 * can have multiple entries for the same file ID in our local database because
 * the unit of account is not actually a file, but a "Collection File": a
 * collection and file pair.
 *
 * For example, if the same file is symlinked into two collections, then we will
 * have two "Collection File" entries for it, both with the same file ID, but
 * with different collection IDs.
 *
 * This function returns files such that only one of these entries (arbitrarily
 * picked in case of dupes) is returned.
 */
export const uniqueFilesByID = (files: EnteFile[]) => {
    const seen = new Set<number>();
    return files.filter(({ id }) => {
        if (seen.has(id)) return false;
        seen.add(id);
        return true;
    });
};

/**
 * Helper function to compute archived collection IDs from their dependencies.
 */
const deriveArchivedCollectionIDs = (collections: Collection[]) =>
    new Set<number>(
        collections
            .filter(isArchivedCollection)
            .map((collection) => collection.id),
    );

/**
 * Helper function to compute the default hidden collection IDs from theirq
 * dependencies.
 */
const deriveDefaultHiddenCollectionIDs = (hiddenCollections: Collection[]) =>
    getDefaultHiddenCollectionIDs(hiddenCollections);

/**
 * Helper function to compute hidden file IDs from their dependencies.
 */
const deriveHiddenFileIDs = (hiddenFiles: EnteFile[]) =>
    new Set<number>(hiddenFiles.map((f) => f.id));

/**
 * Helper function to compute favorite file IDs from their dependencies.
 */
const deriveFavoriteFileIDs = (
    collections: Collection[],
    files: EnteFile[],
): Set<number> => {
    for (const collection of collections) {
        if (collection.type === CollectionType.favorites) {
            return new Set(
                files
                    .filter((file) => file.collectionID === collection.id)
                    .map((file): number => file.id),
            );
        }
    }
    return new Set();
};

/**
 * Helper function to compute collection summaries from their dependencies.
 */
export const deriveCollectionSummaries = (
    user: User,
    collections: Collection[],
    files: EnteFile[],
    trashedFiles: EnteFile[],
    archivedCollectionIDs: Set<number>,
) => {
    const collectionSummaries = createCollectionSummaries(
        user,
        collections,
        files,
    );

    const sectionSummaries = getSectionSummaries(
        files,
        trashedFiles,
        archivedCollectionIDs,
    );

    for (const [key, value] of sectionSummaries) {
        collectionSummaries.set(key, value);
    }

    return collectionSummaries;
};

/**
 * Helper function to compute hidden collection summaries from their
 * dependencies.
 */
export const deriveHiddenCollectionSummaries = (
    user: User,
    hiddenCollections: Collection[],
    hiddenFiles: EnteFile[],
) => {
    const hiddenCollectionSummaries = createCollectionSummaries(
        user,
        hiddenCollections,
        hiddenFiles,
    );
    const hiddenItemsSummaries = getHiddenItemsSummary(
        hiddenFiles,
        hiddenCollections,
    );
    hiddenCollectionSummaries.set(HIDDEN_ITEMS_SECTION, hiddenItemsSummaries);
    return hiddenCollectionSummaries;
};

const createCollectionSummaries = (
    user: User,
    collections: Collection[],
    files: EnteFile[],
): CollectionSummaries => {
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
};

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
    const hiddenItems = uniqueFilesByID(
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
    const archivedFiles = uniqueFilesByID(
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
    const allSectionVisibleFiles = uniqueFilesByID(
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
