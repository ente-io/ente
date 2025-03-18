import {
    isArchivedCollection,
    isPinnedCollection,
} from "@/gallery/services/magic-metadata";
import { type Collection } from "@/media/collection";
import type { EnteFile, FilePrivateMagicMetadata } from "@/media/file";
import { mergeMetadata } from "@/media/file";
import { isArchivedFile } from "@/media/file-metadata";
import {
    createCollectionNameByID,
    isHiddenCollection,
} from "@/new/photos/services/collection";
import { splitByPredicate } from "@/utils/array";
import type { User } from "@ente/shared/user/types";
import { t } from "i18next";
import React, { useReducer } from "react";
import {
    ALL_SECTION,
    ARCHIVE_SECTION,
    DUMMY_UNCATEGORIZED_COLLECTION,
    findDefaultHiddenCollectionIDs,
    HIDDEN_ITEMS_SECTION,
    isDefaultHiddenCollection,
    isIncomingShare,
    TRASH_SECTION,
} from "../../services/collection";
import type {
    CollectionSummary,
    CollectionSummaryType,
} from "../../services/collection/ui";
import {
    createFileCollectionIDs,
    getLatestVersionFiles,
    groupFilesByCollectionID,
    sortFiles,
    uniqueFilesByID,
} from "../../services/files";
import type { PeopleState, Person } from "../../services/ml/people";
import type { SearchSuggestion } from "../../services/search/types";
import type { FamilyData } from "../../services/user-details";

/**
 * Specifies what the bar at the top of the gallery is displaying currently.
 *
 * TODO: Deprecated(?). Use GalleryView instead. Deprecated if it can be used in
 * all cases where the bar mode was in use.
 */
export type GalleryBarMode = "albums" | "hidden-albums" | "people";

/**
 * Specifies what the gallery is currently displaying.
 *
 * This can be overridden by the display of search results.
 */
export type GalleryView =
    | {
          /**
           * We're either in the "Albums" or "Hidden albums" section.
           */
          type: "albums" | "hidden-albums";
          activeCollectionSummaryID: number;
          /**
           * If the active collection ID is for a collection and not a
           * pseudo-collection, this property will be set to the corresponding
           * {@link Collection}.
           *
           * It is guaranteed that this will be one of the {@link collections}
           * or {@link hiddenCollections}.
           */
          activeCollection: Collection | undefined;
      }
    | {
          /**
           * We're in the "People" section.
           */
          type: "people";
          /**
           * The list of people to show in the gallery bar.
           *
           * Note that this can be different from the underlying list of
           * visiblePeople in the {@link peopleState}, and can temporarily
           * include a person from outside that list.
           */
          visiblePeople: Person[];
          /**
           * The currently selected person in the gallery bar, if any.
           *
           * It is guaranteed that when it is set, {@link activePerson} will be
           * one of the objects from among {@link people}.
           */
          activePerson: Person | undefined;
      };

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

    /*--<  Primary state: Files, collections, people  >--*/

    /**
     * The user's normal (non-hidden) collections.
     */
    normalCollections: Collection[];
    /**
     * The user's hidden collections.
     */
    hiddenCollections: Collection[];
    /**
     * The user's normal (non-hidden, non-trash) files, without any unsynced
     * modifications applied to them.
     *
     * The list is sorted so that newer files are first.
     *
     * This property is expected to be of use only internal to the reducer;
     * external code likely needs {@link normalFiles} instead.
     */
    lastSyncedNormalFiles: EnteFile[];
    /**
     * The user's hidden files, without any unsynced modifications applied to
     * them.
     *
     * The list is sorted so that newer files are first.
     *
     * This property is expected to be of use only internal to the reducer;
     * external code likely needs {@link hiddenFiles} instead.
     */
    lastSyncedHiddenFiles: EnteFile[];
    /**
     * The user's files that are in trash.
     *
     * The list is sorted so that newer files are first.
     */
    trashedFiles: EnteFile[];
    /**
     * Latest snapshot of people related state, as reported by
     * {@link usePeopleStateSnapshot}.
     */
    peopleState: PeopleState | undefined;

    /*--<  Derived state  >--*/

    /**
     * The user's normal (non-hidden, non-trash) files, with any unsynced
     * modifications also applied to them.
     *
     * The list is sorted so that newer files are first.
     *
     * [Note: Unsynced modifications]
     *
     * Unsynced modifications are those whose effects have already been made on
     * remote (so thus they have been "saved", so to say), but we still haven't
     * yet refreshed our local state to incorporate them. The refresh will
     * happen on the next "file sync", until then they remain as in-memory state
     * in the reducer.
     */
    normalFiles: EnteFile[];
    /**
     * The user's hidden files, with any unsynced modifications also applied to
     * them.
     *
     * The list is sorted so that newer files are first.
     *
     * See: [Note: Unsynced modifications]
     */
    hiddenFiles: EnteFile[];
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
     *
     * Unlike archived files which can be in a mixture of normal and archived
     * albums, hidden files can only be in hidden albums.
     */
    hiddenFileIDs: Set<number>;
    /**
     * File IDs of the files that the user has archived.
     *
     * Includes the effects of {@link unsyncedVisibilityUpdates}.
     *
     * Files can be individually archived (which is a file level property), or
     * archived by virtue of being placed in an archived album (which is a
     * collection file level property).
     *
     * Archived files are not supposed to be shown in the all section,
     * irrespective of which of those two way they obtain their archive status.
     * In particular, a (collection) file can be both in an archived album and
     * an normal album, so just checking for membership in archived collections
     * is not enough to filter them out from all. Instead, we need to compile a
     * list of file IDs that have the archive status, and then filter the
     * collection files using this list.
     *
     * For fast filtering, this is a set instead of a list.
     */
    archivedFileIDs: Set<number>;
    /**
     * File IDs of all the files that the user has marked as a favorite.
     *
     * Includes the effects of {@link unsyncedFavoriteUpdates}.
     *
     * For fast lookup, this is a set instead of a list.
     */
    favoriteFileIDs: Set<number>;
    /**
     * A map from collection IDs to their user visible name.
     *
     * It will contain entries for all collections (both normal and hidden).
     */
    collectionNameByID: Map<number, string>;
    /**
     * A map from file IDs to the IDs of the normal (non-hidden) collections
     * that they're a part of.
     */
    fileNormalCollectionIDs: Map<number, number[]>;

    /*--<  Derived UI state  >--*/

    /**
     * A map of normal (non-hidden) collections massaged into a form suitable
     * for being directly consumed by the UI, indexed by the collection IDs.
     */
    normalCollectionSummaries: Map<number, CollectionSummary>;
    /**
     * A variant of {@link normalCollectionSummaries}, but for hidden
     * collections.
     */
    hiddenCollectionSummaries: Map<number, CollectionSummary>;

    /*--<  In-flight updates  >--*/

    /**
     * File IDs of the files that have been just been deleted by the user.
     *
     * The delete on remote for these has either completed, or is currently in
     * flight, but the local state has not yet been updated. We stash these
     * changes here temporarily so that the UI can reflect the changes until our
     * local state also gets synced in a bit.
     */
    tempDeletedFileIDs: Set<number>;
    /**
     * Variant of {@link tempDeletedFileIDs} for files that have just been
     * hidden.
     */
    tempHiddenFileIDs: Set<number>;
    /**
     * File (IDs) for which there is currently an in-flight favorite /
     * unfavorite operation.
     *
     * See also {@link unsyncedFavoriteUpdates}.
     */
    pendingFavoriteUpdates: Set<number>;
    /**
     * Updates to the favorite status of files (triggered by some interactive
     * user action) that have already been made to applied to remote, but whose
     * effects on remote have not yet been synced back to our local DB.
     *
     * Each entry from a file ID to its favorite status (`true` if it belongs to
     * the user's favorites, false otherwise) which should be used for that file
     * instead of what we get from our local DB.
     *
     * The next time a sync with remote completes, we clear this map since
     * thereafter just deriving {@link favoriteFileIDs} from our local files
     * would reflect the correct state on remote too.
     */
    unsyncedFavoriteUpdates: Map<number, boolean>;
    /**
     * File (IDs) for which there is currently an in-flight archive / unarchive
     * operation.
     *
     * See also {@link unsyncedPrivateMagicMetadataUpdates}.
     */
    pendingVisibilityUpdates: Set<number>;
    /**
     * Updates to file magic metadata (triggered by some interactive user
     * action) that have already been made to applied to remote, but whose
     * effects on remote have not yet been synced back to our local DB.
     *
     * Each entry from a file ID to the magic metadata that should be used for
     * that file instead of what we get from our local DB.
     *
     * The next time a sync with remote completes, we clear this map since
     * thereafter the synced files themselves will reflect the latest private
     * magic metadata.
     */
    unsyncedPrivateMagicMetadataUpdates: Map<number, FilePrivateMagicMetadata>;

    /*--<  State that underlies transient UI state  >--*/

    /**
     * The currently selected collection summary, if any.
     *
     * When present, this is used to derive the
     * {@link activeCollectionSummaryID} property of the {@link view}.
     *
     * UI code should use the {@link view}, this property is meant as the
     * underlying primitive state. In particular, this does not get reset when
     * we switch sections, which allows us to come back to the same active
     * collection (if possible) on switching back.
     */
    selectedCollectionSummaryID: number | undefined;
    /**
     * The currently selected person, if any.
     *
     * When present, it is used to derive the {@link activePerson} property of
     * the {@link view}.
     *
     * UI code should use the {@link view}, this property is meant as the
     * underlying primitive state. In particular, this does not get reset when
     * we switch sections, which allows us to come back to the same person (if
     * possible) on switching back.
     */
    selectedPersonID: string | undefined;
    /**
     * If present, this person is tacked on the the list of visible people
     * temporarily (until the user switches out from the people view).
     *
     * This is needed to retain a usually non-visible but temporarily selected
     * person in the people bar until the user switches to some other view.
     */
    extraVisiblePerson: Person | undefined;
    /**
     * The suggestion selected by the user from the search bar dropdown.
     *
     * This is used to compute the {@link searchResults}.
     */
    searchSuggestion: SearchSuggestion | undefined;
    /**
     * List of files that match the selected search option.
     *
     * This will be set only if we are showing search results.
     *
     * The search dropdown shows a list of options ("suggestions") that match
     * the user's search term. If the user selects from one of these options,
     * then we run a search to find all files that match that suggestion, and
     * set this value to the result.
     */
    searchResults: EnteFile[] | undefined;
    /**
     * `true` an external effect is currently (asynchronously) updating search
     * results.
     */
    isRecomputingSearchResults: boolean;
    /**
     * {@link SearchSuggestion}s that have been enqueued while we were
     * recomputing the current search results.
     *
     * We only need the last element of this array (if any), the rest are
     * discarded when we get around to processing these.
     */
    pendingSearchSuggestions: SearchSuggestion[];

    /*--<  Transient UI state  >--*/

    /**
     * The view, and the item within it, that the gallery is currently showing.
     *
     * This can be temporarily overridden when we display search results.
     */
    view: GalleryView | undefined;
    /**
     * `true` if we are in "search mode".
     *
     * We will always be in search mode if we are showing search results, but we
     * also may be in search mode earlier on smaller screens, where the search
     * input is only shown on entering search mode. See: [Note: "Search mode"].
     *
     * That is, {@link isInSearchMode} may be true even when
     * {@link searchResults} is undefined.
     *
     * We will be _showing_ search results if both {@link isInSearchMode} is
     * `true` and {@link searchResults} is defined.
     */
    isInSearchMode: boolean;
    /**
     * The files to show, uniqued and sorted appropriately.
     */
    filteredFiles: EnteFile[];
}

export type GalleryAction =
    | {
          type: "mount";
          user: User;
          familyData: FamilyData;
          collections: Collection[];
          normalFiles: EnteFile[];
          hiddenFiles: EnteFile[];
          trashedFiles: EnteFile[];
      }
    | {
          type: "setCollections";
          collections: Collection[];
          normalCollections: Collection[];
          hiddenCollections: Collection[];
      }
    | { type: "setNormalCollections"; collections: Collection[] }
    | { type: "setNormalFiles"; files: EnteFile[] }
    | { type: "fetchNormalFiles"; files: EnteFile[] }
    | { type: "uploadNormalFile"; file: EnteFile }
    | { type: "setHiddenFiles"; files: EnteFile[] }
    | { type: "fetchHiddenFiles"; files: EnteFile[] }
    | { type: "setTrashedFiles"; files: EnteFile[] }
    | { type: "setPeopleState"; peopleState: PeopleState | undefined }
    | { type: "markTempDeleted"; files: EnteFile[] }
    | { type: "clearTempDeleted" }
    | { type: "markTempHidden"; files: EnteFile[] }
    | { type: "clearTempHidden" }
    | { type: "addPendingFavoriteUpdate"; fileID: number }
    | { type: "removePendingFavoriteUpdate"; fileID: number }
    | { type: "unsyncedFavoriteUpdate"; fileID: number; isFavorite: boolean }
    | { type: "addPendingVisibilityUpdate"; fileID: number }
    | { type: "removePendingVisibilityUpdate"; fileID: number }
    | {
          type: "unsyncedPrivateMagicMetadataUpdate";
          fileID: number;
          privateMagicMetadata: FilePrivateMagicMetadata;
      }
    | { type: "clearUnsyncedState" }
    | { type: "showAll" }
    | { type: "showHidden" }
    | { type: "showAlbums" }
    | { type: "showCollectionSummary"; collectionSummaryID: number | undefined }
    | { type: "showPeople" }
    | { type: "showPerson"; personID: string }
    | { type: "enterSearchMode"; searchSuggestion?: SearchSuggestion }
    | { type: "updatingSearchResults" }
    | { type: "setSearchResults"; searchResults: EnteFile[] }
    | { type: "exitSearch" };

const initialGalleryState: GalleryState = {
    user: undefined,
    familyData: undefined,
    normalCollections: [],
    hiddenCollections: [],
    lastSyncedNormalFiles: [],
    lastSyncedHiddenFiles: [],
    trashedFiles: [],
    peopleState: undefined,
    normalFiles: [],
    hiddenFiles: [],
    archivedCollectionIDs: new Set(),
    defaultHiddenCollectionIDs: new Set(),
    hiddenFileIDs: new Set(),
    archivedFileIDs: new Set(),
    favoriteFileIDs: new Set(),
    collectionNameByID: new Map(),
    fileNormalCollectionIDs: new Map(),
    normalCollectionSummaries: new Map(),
    hiddenCollectionSummaries: new Map(),
    tempDeletedFileIDs: new Set(),
    tempHiddenFileIDs: new Set(),
    pendingFavoriteUpdates: new Set(),
    unsyncedFavoriteUpdates: new Map(),
    pendingVisibilityUpdates: new Set(),
    unsyncedPrivateMagicMetadataUpdates: new Map(),
    selectedCollectionSummaryID: undefined,
    selectedPersonID: undefined,
    extraVisiblePerson: undefined,
    searchSuggestion: undefined,
    searchResults: undefined,
    isRecomputingSearchResults: false,
    pendingSearchSuggestions: [],
    view: undefined,
    filteredFiles: [],
    isInSearchMode: false,
};

const galleryReducer: React.Reducer<GalleryState, GalleryAction> = (
    state,
    action,
) => {
    if (process.env.NEXT_PUBLIC_ENTE_TRACE) console.log("dispatch", action);
    switch (action.type) {
        case "mount": {
            const lastSyncedNormalFiles = sortFiles(
                mergeMetadata(action.normalFiles),
            );
            const lastSyncedHiddenFiles = sortFiles(
                mergeMetadata(action.hiddenFiles),
            );

            // During mount there are no unsynced updates, and we can directly
            // use the provided files.
            const normalFiles = lastSyncedNormalFiles;
            const hiddenFiles = lastSyncedHiddenFiles;

            const [hiddenCollections, normalCollections] = splitByPredicate(
                action.collections,
                isHiddenCollection,
            );
            const hiddenFileIDs = deriveHiddenFileIDs(hiddenFiles);
            const archivedCollectionIDs =
                deriveArchivedCollectionIDs(normalCollections);
            const archivedFileIDs = deriveArchivedFileIDs(
                archivedCollectionIDs,
                normalFiles,
            );
            const view = {
                type: "albums" as const,
                activeCollectionSummaryID: ALL_SECTION,
                activeCollection: undefined,
            };

            return stateByUpdatingFilteredFiles({
                ...state,
                user: action.user,
                familyData: action.familyData,
                normalCollections,
                hiddenCollections,
                lastSyncedNormalFiles,
                lastSyncedHiddenFiles,
                trashedFiles: action.trashedFiles,
                normalFiles,
                hiddenFiles,
                archivedCollectionIDs,
                defaultHiddenCollectionIDs:
                    deriveDefaultHiddenCollectionIDs(hiddenCollections),
                hiddenFileIDs,
                archivedFileIDs,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    normalCollections,
                    normalFiles,
                    state.unsyncedFavoriteUpdates,
                ),
                collectionNameByID: createCollectionNameByID(
                    action.collections,
                ),
                fileNormalCollectionIDs: createFileCollectionIDs(normalFiles),
                normalCollectionSummaries: deriveNormalCollectionSummaries(
                    action.user,
                    normalCollections,
                    normalFiles,
                    action.trashedFiles,
                    archivedFileIDs,
                ),
                hiddenCollectionSummaries: deriveHiddenCollectionSummaries(
                    action.user,
                    hiddenCollections,
                    hiddenFiles,
                ),
                view,
            });
        }

        case "setCollections": {
            const { collections, normalCollections, hiddenCollections } =
                action;
            const archivedCollectionIDs =
                deriveArchivedCollectionIDs(normalCollections);
            const archivedFileIDs = deriveArchivedFileIDs(
                archivedCollectionIDs,
                state.normalFiles,
            );
            const normalCollectionSummaries = deriveNormalCollectionSummaries(
                state.user!,
                normalCollections,
                state.normalFiles,
                state.trashedFiles,
                archivedFileIDs,
            );
            const hiddenCollectionSummaries = deriveHiddenCollectionSummaries(
                state.user!,
                hiddenCollections,
                state.hiddenFiles,
            );

            // Revalidate the active view if needed.
            let view = state.view;
            let selectedCollectionSummaryID = state.selectedCollectionSummaryID;
            if (state.view?.type == "albums") {
                ({ view, selectedCollectionSummaryID } =
                    deriveAlbumsViewAndSelectedID(
                        normalCollections,
                        normalCollectionSummaries,
                        selectedCollectionSummaryID,
                    ));
            } else if (state.view?.type == "hidden-albums") {
                ({ view, selectedCollectionSummaryID } =
                    deriveHiddenAlbumsViewAndSelectedID(
                        hiddenCollections,
                        hiddenCollectionSummaries,
                        selectedCollectionSummaryID,
                    ));
            }

            return stateByUpdatingFilteredFiles({
                ...state,
                normalCollections,
                hiddenCollections,
                archivedCollectionIDs,
                defaultHiddenCollectionIDs:
                    deriveDefaultHiddenCollectionIDs(hiddenCollections),
                archivedFileIDs,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    normalCollections,
                    state.normalFiles,
                    state.unsyncedFavoriteUpdates,
                ),
                collectionNameByID: createCollectionNameByID(collections),
                normalCollectionSummaries,
                hiddenCollectionSummaries,
                selectedCollectionSummaryID,
                pendingSearchSuggestions:
                    enqueuePendingSearchSuggestionsIfNeeded(
                        state.searchSuggestion,
                        state.pendingSearchSuggestions,
                        state.isInSearchMode,
                    ),
                view,
            });
        }

        case "setNormalCollections": {
            const normalCollections = action.collections;
            const archivedCollectionIDs =
                deriveArchivedCollectionIDs(normalCollections);
            const archivedFileIDs = deriveArchivedFileIDs(
                archivedCollectionIDs,
                state.normalFiles,
            );
            const normalCollectionSummaries = deriveNormalCollectionSummaries(
                state.user!,
                normalCollections,
                state.normalFiles,
                state.trashedFiles,
                archivedFileIDs,
            );

            // Revalidate the active view if needed.
            let view = state.view;
            let selectedCollectionSummaryID = state.selectedCollectionSummaryID;
            if (state.view?.type == "albums") {
                ({ view, selectedCollectionSummaryID } =
                    deriveAlbumsViewAndSelectedID(
                        normalCollections,
                        normalCollectionSummaries,
                        selectedCollectionSummaryID,
                    ));
            }

            return stateByUpdatingFilteredFiles({
                ...state,
                normalCollections,
                archivedCollectionIDs,
                archivedFileIDs,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    normalCollections,
                    state.normalFiles,
                    state.unsyncedFavoriteUpdates,
                ),
                collectionNameByID: createCollectionNameByID(
                    normalCollections.concat(state.hiddenCollections),
                ),
                normalCollectionSummaries,
                selectedCollectionSummaryID,
                pendingSearchSuggestions:
                    enqueuePendingSearchSuggestionsIfNeeded(
                        state.searchSuggestion,
                        state.pendingSearchSuggestions,
                        state.isInSearchMode,
                    ),
                view,
            });
        }

        case "setNormalFiles": {
            const unsyncedPrivateMagicMetadataUpdates =
                prunedUnsyncedPrivateMagicMetadataUpdates(
                    state.unsyncedPrivateMagicMetadataUpdates,
                    action.files,
                );
            const lastSyncedNormalFiles = sortFiles(
                mergeMetadata(action.files),
            );
            const normalFiles = deriveFiles(
                lastSyncedNormalFiles,
                unsyncedPrivateMagicMetadataUpdates,
            );

            return stateByUpdatingFilteredFiles({
                ...stateForUpdatedNormalFiles(state, normalFiles),
                lastSyncedNormalFiles,
                unsyncedPrivateMagicMetadataUpdates,
            });
        }

        case "fetchNormalFiles": {
            const unsyncedPrivateMagicMetadataUpdates =
                prunedUnsyncedPrivateMagicMetadataUpdates(
                    state.unsyncedPrivateMagicMetadataUpdates,
                    action.files,
                );
            const lastSyncedNormalFiles = sortFiles(
                mergeMetadata(
                    getLatestVersionFiles(
                        state.lastSyncedNormalFiles.concat(action.files),
                    ),
                ),
            );
            const normalFiles = deriveFiles(
                lastSyncedNormalFiles,
                unsyncedPrivateMagicMetadataUpdates,
            );

            return stateByUpdatingFilteredFiles({
                ...stateForUpdatedNormalFiles(state, normalFiles),
                lastSyncedNormalFiles,
                unsyncedPrivateMagicMetadataUpdates,
            });
        }

        case "uploadNormalFile": {
            // TODO: Consider batching this instead of doing it per file
            // upload to speed up uploads. Perf test first though.

            const lastSyncedNormalFiles = sortFiles([
                ...state.lastSyncedNormalFiles,
                action.file,
            ]);
            const normalFiles = deriveFiles(
                lastSyncedNormalFiles,
                state.unsyncedPrivateMagicMetadataUpdates,
            );

            return stateByUpdatingFilteredFiles({
                ...stateForUpdatedNormalFiles(state, normalFiles),
                lastSyncedNormalFiles,
            });
        }

        case "setHiddenFiles": {
            const unsyncedPrivateMagicMetadataUpdates =
                prunedUnsyncedPrivateMagicMetadataUpdates(
                    state.unsyncedPrivateMagicMetadataUpdates,
                    action.files,
                );
            const lastSyncedHiddenFiles = sortFiles(
                mergeMetadata(action.files),
            );
            const hiddenFiles = deriveFiles(
                lastSyncedHiddenFiles,
                unsyncedPrivateMagicMetadataUpdates,
            );

            return stateByUpdatingFilteredFiles({
                ...stateForUpdatedHiddenFiles(state, hiddenFiles),
                lastSyncedHiddenFiles,
                unsyncedPrivateMagicMetadataUpdates,
            });
        }

        case "fetchHiddenFiles": {
            const unsyncedPrivateMagicMetadataUpdates =
                prunedUnsyncedPrivateMagicMetadataUpdates(
                    state.unsyncedPrivateMagicMetadataUpdates,
                    action.files,
                );
            const lastSyncedHiddenFiles = sortFiles(
                mergeMetadata(
                    getLatestVersionFiles(
                        state.lastSyncedHiddenFiles.concat(action.files),
                    ),
                ),
            );
            const hiddenFiles = deriveFiles(
                lastSyncedHiddenFiles,
                unsyncedPrivateMagicMetadataUpdates,
            );

            return stateByUpdatingFilteredFiles({
                ...stateForUpdatedHiddenFiles(state, hiddenFiles),
                lastSyncedHiddenFiles,
                unsyncedPrivateMagicMetadataUpdates,
            });
        }

        case "setTrashedFiles":
            return stateByUpdatingFilteredFiles({
                ...state,
                trashedFiles: action.files,
                normalCollectionSummaries: deriveNormalCollectionSummaries(
                    state.user!,
                    state.normalCollections,
                    state.normalFiles,
                    action.files,
                    state.archivedFileIDs,
                ),
            });

        case "setPeopleState": {
            const peopleState = action.peopleState;

            if (state.view?.type != "people") return { ...state, peopleState };

            const { view, extraVisiblePerson } = derivePeopleView(
                peopleState,
                state.tempDeletedFileIDs,
                state.tempHiddenFileIDs,
                state.selectedPersonID,
                state.extraVisiblePerson,
            );
            return stateByUpdatingFilteredFiles({
                ...state,
                peopleState,
                selectedPersonID: view.activePerson?.id,
                extraVisiblePerson,
                view,
            });
        }

        case "markTempDeleted":
            return stateByUpdatingFilteredFiles({
                ...state,
                tempDeletedFileIDs: new Set(
                    [...state.tempDeletedFileIDs].concat(
                        action.files.map((f) => f.id),
                    ),
                ),
            });

        case "clearTempDeleted":
            return stateByUpdatingFilteredFiles({
                ...state,
                tempDeletedFileIDs: new Set(),
            });

        case "markTempHidden":
            return stateByUpdatingFilteredFiles({
                ...state,
                tempHiddenFileIDs: new Set(
                    [...state.tempHiddenFileIDs].concat(
                        action.files.map((f) => f.id),
                    ),
                ),
            });

        case "clearTempHidden":
            return stateByUpdatingFilteredFiles({
                ...state,
                tempHiddenFileIDs: new Set(),
            });

        case "addPendingFavoriteUpdate": {
            const pendingFavoriteUpdates = new Set(
                state.pendingFavoriteUpdates,
            );
            pendingFavoriteUpdates.add(action.fileID);
            return { ...state, pendingFavoriteUpdates };
        }

        case "removePendingFavoriteUpdate": {
            const pendingFavoriteUpdates = new Set(
                state.pendingFavoriteUpdates,
            );
            pendingFavoriteUpdates.delete(action.fileID);
            return { ...state, pendingFavoriteUpdates };
        }

        case "unsyncedFavoriteUpdate": {
            const unsyncedFavoriteUpdates = new Map(
                state.unsyncedFavoriteUpdates,
            );
            unsyncedFavoriteUpdates.set(action.fileID, action.isFavorite);

            // Skipping a call to stateByUpdatingFilteredFiles since it
            // currently doesn't depend on favorites.
            return {
                ...state,
                favoriteFileIDs: deriveFavoriteFileIDs(
                    state.normalCollections,
                    state.normalFiles,
                    unsyncedFavoriteUpdates,
                ),
                unsyncedFavoriteUpdates,
            };
        }

        case "addPendingVisibilityUpdate": {
            const pendingVisibilityUpdates = new Set(
                state.pendingVisibilityUpdates,
            );
            pendingVisibilityUpdates.add(action.fileID);
            // Not using stateByUpdatingFilteredFiles since it does not depend
            // on pendingVisibilityUpdates.
            return { ...state, pendingVisibilityUpdates };
        }

        case "removePendingVisibilityUpdate": {
            const pendingVisibilityUpdates = new Set(
                state.pendingVisibilityUpdates,
            );
            pendingVisibilityUpdates.delete(action.fileID);
            return { ...state, pendingVisibilityUpdates };
        }

        case "unsyncedPrivateMagicMetadataUpdate": {
            const unsyncedPrivateMagicMetadataUpdates = new Map(
                state.unsyncedPrivateMagicMetadataUpdates,
            );
            unsyncedPrivateMagicMetadataUpdates.set(
                action.fileID,
                action.privateMagicMetadata,
            );
            const normalFiles = deriveFiles(
                state.lastSyncedNormalFiles,
                unsyncedPrivateMagicMetadataUpdates,
            );

            return stateByUpdatingFilteredFiles({
                ...stateForUpdatedNormalFiles(state, normalFiles),
                unsyncedPrivateMagicMetadataUpdates,
            });
        }

        case "clearUnsyncedState": {
            const unsyncedFavoriteUpdates: GalleryState["unsyncedFavoriteUpdates"] =
                new Map();
            const favoriteFileIDs = deriveFavoriteFileIDs(
                state.normalCollections,
                state.normalFiles,
                unsyncedFavoriteUpdates,
            );

            const unsyncedPrivateMagicMetadataUpdates: GalleryState["unsyncedPrivateMagicMetadataUpdates"] =
                new Map();
            const normalFiles = deriveFiles(
                state.lastSyncedNormalFiles,
                unsyncedPrivateMagicMetadataUpdates,
            );
            const hiddenFiles = deriveFiles(
                state.lastSyncedHiddenFiles,
                unsyncedPrivateMagicMetadataUpdates,
            );

            return stateByUpdatingFilteredFiles(
                stateForUpdatedHiddenFiles(
                    stateForUpdatedNormalFiles(
                        {
                            ...state,
                            favoriteFileIDs,
                            tempDeletedFileIDs: new Set(),
                            tempHiddenFileIDs: new Set(),
                            pendingFavoriteUpdates: new Set(),
                            pendingVisibilityUpdates: new Set(),
                            unsyncedPrivateMagicMetadataUpdates,
                            unsyncedFavoriteUpdates: new Map(),
                        },
                        normalFiles,
                    ),
                    hiddenFiles,
                ),
            );
        }

        case "showAll":
            return stateByUpdatingFilteredFiles({
                ...state,
                selectedCollectionSummaryID: undefined,
                extraVisiblePerson: undefined,
                searchSuggestion: undefined,
                searchResults: undefined,
                isRecomputingSearchResults: false,
                pendingSearchSuggestions: [],
                view: {
                    type: "albums",
                    activeCollectionSummaryID: ALL_SECTION,
                    activeCollection: undefined,
                },
                isInSearchMode: false,
            });

        case "showHidden":
            return stateByUpdatingFilteredFiles({
                ...state,
                selectedCollectionSummaryID: undefined,
                extraVisiblePerson: undefined,
                searchSuggestion: undefined,
                searchResults: undefined,
                isRecomputingSearchResults: false,
                pendingSearchSuggestions: [],
                view: {
                    type: "hidden-albums",
                    activeCollectionSummaryID: HIDDEN_ITEMS_SECTION,
                    activeCollection: undefined,
                },
                isInSearchMode: false,
            });

        case "showAlbums": {
            const { view, selectedCollectionSummaryID } =
                deriveAlbumsViewAndSelectedID(
                    state.normalCollections,
                    state.normalCollectionSummaries,
                    state.selectedCollectionSummaryID,
                );

            return stateByUpdatingFilteredFiles({
                ...state,
                selectedCollectionSummaryID,
                extraVisiblePerson: undefined,
                searchSuggestion: undefined,
                searchResults: undefined,
                isRecomputingSearchResults: false,
                pendingSearchSuggestions: [],
                view,
                isInSearchMode: false,
            });
        }

        case "showCollectionSummary":
            return stateByUpdatingFilteredFiles({
                ...state,
                selectedCollectionSummaryID: action.collectionSummaryID,
                extraVisiblePerson: undefined,
                searchResults: undefined,
                searchSuggestion: undefined,
                isRecomputingSearchResults: false,
                pendingSearchSuggestions: [],
                view: {
                    type:
                        action.collectionSummaryID !== undefined &&
                        state.hiddenCollectionSummaries.has(
                            action.collectionSummaryID,
                        )
                            ? "hidden-albums"
                            : "albums",
                    activeCollectionSummaryID:
                        action.collectionSummaryID ?? ALL_SECTION,
                    activeCollection: state.normalCollections
                        .concat(state.hiddenCollections)
                        .find(({ id }) => id === action.collectionSummaryID),
                },
                isInSearchMode: false,
            });

        case "showPeople": {
            const { view, extraVisiblePerson } = derivePeopleView(
                state.peopleState,
                state.tempDeletedFileIDs,
                state.tempHiddenFileIDs,
                state.selectedPersonID,
                state.extraVisiblePerson,
            );
            return stateByUpdatingFilteredFiles({
                ...state,
                selectedPersonID: view.activePerson?.id,
                extraVisiblePerson,
                searchResults: undefined,
                searchSuggestion: undefined,
                isRecomputingSearchResults: false,
                pendingSearchSuggestions: [],
                view,
                isInSearchMode: false,
            });
        }

        case "showPerson": {
            const { view, extraVisiblePerson } = derivePeopleView(
                state.peopleState,
                state.tempDeletedFileIDs,
                state.tempHiddenFileIDs,
                action.personID,
                state.extraVisiblePerson,
            );
            return stateByUpdatingFilteredFiles({
                ...state,
                selectedPersonID: view.activePerson?.id,
                extraVisiblePerson,
                searchResults: undefined,
                searchSuggestion: undefined,
                isRecomputingSearchResults: false,
                pendingSearchSuggestions: [],
                view,
                isInSearchMode: false,
            });
        }

        case "enterSearchMode": {
            const pendingSearchSuggestions = action.searchSuggestion
                ? [...state.pendingSearchSuggestions, action.searchSuggestion]
                : state.pendingSearchSuggestions;

            return stateByUpdatingFilteredFiles({
                ...state,
                isInSearchMode: true,
                searchSuggestion: action.searchSuggestion,
                pendingSearchSuggestions,
            });
        }

        case "updatingSearchResults":
            return stateByUpdatingFilteredFiles({
                ...state,
                isRecomputingSearchResults: true,
                pendingSearchSuggestions: [],
            });

        case "setSearchResults":
            // Discard stale updates
            if (!state.isRecomputingSearchResults) return state;

            return stateByUpdatingFilteredFiles({
                ...state,
                searchResults: action.searchResults,
                isRecomputingSearchResults: false,
            });

        case "exitSearch":
            return stateByUpdatingFilteredFiles({
                ...state,
                searchResults: undefined,
                searchSuggestion: undefined,
                isRecomputingSearchResults: false,
                pendingSearchSuggestions: [],
                isInSearchMode: false,
            });
    }
};

export const useGalleryReducer = () =>
    useReducer(galleryReducer, initialGalleryState);

/**
 * Compute the effective files that we should use by overlaying the files we
 * read from disk by any temporary unsynced updates.
 */
const deriveFiles = (
    files: EnteFile[],
    unsyncedPrivateMagicMetadataUpdates: GalleryState["unsyncedPrivateMagicMetadataUpdates"],
) => {
    // Happy fastpath.
    if (unsyncedPrivateMagicMetadataUpdates.size == 0) return files;

    // We have one or more unsynced private magic metadata updates that should
    // be applied to all the collection files with the matching file ID.
    return files.map((file) => {
        const privateMagicMetadata = unsyncedPrivateMagicMetadataUpdates.get(
            file.id,
        );
        if (!privateMagicMetadata) return file;

        return { ...file, magicMetadata: privateMagicMetadata };
    });
};

/**
 * Compute archived collection IDs from their dependencies.
 */
const deriveArchivedCollectionIDs = (collections: Collection[]) =>
    new Set<number>(
        collections
            .filter(isArchivedCollection)
            .map((collection) => collection.id),
    );

/**
 * Compute the default hidden collection IDs from their dependencies.
 */
const deriveDefaultHiddenCollectionIDs = (hiddenCollections: Collection[]) =>
    findDefaultHiddenCollectionIDs(hiddenCollections);

/**
 * Compute hidden file IDs from their dependencies.
 */
const deriveHiddenFileIDs = (hiddenFiles: EnteFile[]) =>
    new Set<number>(hiddenFiles.map((f) => f.id));

/**
 * Compute archived file IDs from their dependencies.
 */
const deriveArchivedFileIDs = (
    archivedCollectionIDs: GalleryState["archivedCollectionIDs"],
    files: GalleryState["normalFiles"],
) =>
    new Set(
        files
            .filter(
                (file) =>
                    isArchivedFile(file) ||
                    archivedCollectionIDs.has(file.collectionID),
            )
            .map((f) => f.id),
    );

/**
 * Compute favorite file IDs from their dependencies.
 */
const deriveFavoriteFileIDs = (
    collections: Collection[],
    files: EnteFile[],
    unsyncedFavoriteUpdates: GalleryState["unsyncedFavoriteUpdates"],
) => {
    let favoriteFileIDs = new Set<number>();
    for (const collection of collections) {
        if (collection.type == "favorites") {
            favoriteFileIDs = new Set(
                files
                    .filter((file) => file.collectionID === collection.id)
                    .map((file) => file.id),
            );
            break;
        }
    }
    for (const [fileID, isFavorite] of unsyncedFavoriteUpdates.entries()) {
        if (isFavorite) favoriteFileIDs.add(fileID);
        else favoriteFileIDs.delete(fileID);
    }
    return favoriteFileIDs;
};

/**
 * Compute normal (non-hidden) collection summaries from their dependencies.
 */
const deriveNormalCollectionSummaries = (
    user: User,
    normalCollections: Collection[],
    normalFiles: EnteFile[],
    trashedFiles: EnteFile[],
    archivedFileIDs: Set<number>,
) => {
    const normalCollectionSummaries = createCollectionSummaries(
        user,
        normalCollections,
        normalFiles,
    );

    const uncategorizedCollection = normalCollections.find(
        ({ type }) => type == "uncategorized",
    );
    if (!uncategorizedCollection) {
        normalCollectionSummaries.set(DUMMY_UNCATEGORIZED_COLLECTION, {
            ...pseudoCollectionOptionsForFiles([]),
            id: DUMMY_UNCATEGORIZED_COLLECTION,
            type: "uncategorized",
            attributes: ["uncategorized"],
            name: t("section_uncategorized"),
        });
    }

    const allSectionFiles = findAllSectionVisibleFiles(
        normalFiles,
        archivedFileIDs,
    );
    normalCollectionSummaries.set(ALL_SECTION, {
        ...pseudoCollectionOptionsForFiles(allSectionFiles),
        id: ALL_SECTION,
        type: "all",
        attributes: ["all"],
        name: t("section_all"),
    });
    normalCollectionSummaries.set(TRASH_SECTION, {
        ...pseudoCollectionOptionsForFiles(trashedFiles),
        id: TRASH_SECTION,
        name: t("section_trash"),
        type: "trash",
        attributes: ["trash"],
        coverFile: undefined,
    });
    const archivedFiles = uniqueFilesByID(
        normalFiles.filter((file) => isArchivedFile(file)),
    );
    normalCollectionSummaries.set(ARCHIVE_SECTION, {
        ...pseudoCollectionOptionsForFiles(archivedFiles),
        id: ARCHIVE_SECTION,
        name: t("section_archive"),
        type: "archive",
        attributes: ["archive"],
        coverFile: undefined,
    });

    return normalCollectionSummaries;
};

const pseudoCollectionOptionsForFiles = (files: EnteFile[]) => ({
    coverFile: files[0],
    latestFile: files[0],
    fileCount: files.length,
    updationTime: files[0]?.updationTime,
});

/**
 * Compute hidden collection summaries from their dependencies.
 */
const deriveHiddenCollectionSummaries = (
    user: User,
    hiddenCollections: Collection[],
    hiddenFiles: EnteFile[],
) => {
    const hiddenCollectionSummaries = createCollectionSummaries(
        user,
        hiddenCollections,
        hiddenFiles,
    );

    const dhcIDs = findDefaultHiddenCollectionIDs(hiddenCollections);
    const defaultHiddenFiles = uniqueFilesByID(
        hiddenFiles.filter((file) => dhcIDs.has(file.collectionID)),
    );
    hiddenCollectionSummaries.set(HIDDEN_ITEMS_SECTION, {
        ...pseudoCollectionOptionsForFiles(defaultHiddenFiles),
        id: HIDDEN_ITEMS_SECTION,
        name: t("hidden_items"),
        type: "hiddenItems",
        attributes: ["hiddenItems"],
    });

    return hiddenCollectionSummaries;
};

const createCollectionSummaries = (
    user: User,
    collections: Collection[],
    files: EnteFile[],
) => {
    const collectionSummaries = new Map<number, CollectionSummary>();

    const filesByCollection = groupFilesByCollectionID(files);
    const coverFiles = findCoverFiles(collections, filesByCollection);

    for (const collection of collections) {
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
            type = collection.type;
        }

        // This block of code duplicates the above. Such duplication is needed
        // until type is completely replaced by attributes.
        const attributes: CollectionSummaryType[] = [];
        if (isIncomingShare(collection, user)) {
            if (isIncomingCollabShare(collection, user)) {
                attributes.push("incomingShareCollaborator");
            } else {
                attributes.push("incomingShareViewer");
            }
        }
        if (isOutgoingShare(collection, user)) {
            attributes.push("outgoingShare");
        }
        if (isSharedOnlyViaLink(collection)) {
            attributes.push("sharedOnlyViaLink");
        }
        if (isArchivedCollection(collection)) {
            attributes.push("archived");
        }
        if (isDefaultHiddenCollection(collection)) {
            attributes.push("defaultHidden");
        }
        if (isPinnedCollection(collection)) {
            attributes.push("pinned");
        }
        // TODO: Verify type before removing the null check.
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (collection.type) attributes.push(collection.type);

        let name: string;
        if (type == "uncategorized") {
            name = t("section_uncategorized");
        } else if (type == "favorites") {
            name = t("favorites");
        } else {
            name = collection.name;
        }

        const collectionFiles = filesByCollection.get(collection.id);
        collectionSummaries.set(collection.id, {
            id: collection.id,
            type,
            attributes,
            name,
            latestFile: collectionFiles?.[0],
            coverFile: coverFiles.get(collection.id),
            fileCount: collectionFiles?.length ?? 0,
            updationTime: collection.updationTime,
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
            order: collection.magicMetadata?.data?.order ?? 0,
        });
    }

    return collectionSummaries;
};

const findCoverFiles = (
    collections: Collection[],
    filesByCollection: Map<number, EnteFile[]>,
): Map<number, EnteFile> => {
    const coverFiles = new Map<number, EnteFile>();
    for (const collection of collections) {
        const collectionFiles = filesByCollection.get(collection.id);
        if (!collectionFiles || collectionFiles.length == 0) continue;

        let coverFile: EnteFile | undefined;

        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        const coverID = collection.pubMagicMetadata?.data?.coverID;
        if (typeof coverID === "number" && coverID > 0) {
            coverFile = collectionFiles.find(({ id }) => id === coverID);
        }

        if (!coverFile) {
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
            if (collection.pubMagicMetadata?.data?.asc) {
                coverFile = collectionFiles[collectionFiles.length - 1];
            } else {
                coverFile = collectionFiles[0];
            }
        }

        if (coverFile) {
            coverFiles.set(collection.id, coverFile);
        }
    }
    return coverFiles;
};

const isIncomingCollabShare = (collection: Collection, user: User) => {
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    const sharee = collection.sharees?.find((sharee) => sharee.id === user.id);
    return sharee?.role == "COLLABORATOR";
};

const isOutgoingShare = (collection: Collection, user: User) =>
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.owner.id === user.id && collection.sharees?.length > 0;

const isSharedOnlyViaLink = (collection: Collection) =>
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.publicURLs?.length && !collection.sharees?.length;

/**
 * Return all list of files that should be shown in the "All" section.
 */
const findAllSectionVisibleFiles = (
    files: EnteFile[],
    archivedFileIDs: Set<number>,
) => uniqueFilesByID(files.filter(({ id }) => !archivedFileIDs.has(id)));

/**
 * Compute the {@link GalleryView} from its dependencies when we are switching
 * to (or back to) the "albums" view, or the underlying collections might've
 * changed.
 */
const deriveAlbumsViewAndSelectedID = (
    collections: GalleryState["normalCollections"],
    collectionSummaries: GalleryState["normalCollectionSummaries"],
    selectedCollectionSummaryID: GalleryState["selectedCollectionSummaryID"],
) => {
    // Make sure that the last selected ID is still valid by searching for it.
    const activeCollectionSummaryID = selectedCollectionSummaryID
        ? collectionSummaries.get(selectedCollectionSummaryID)?.id
        : undefined;
    const activeCollection = activeCollectionSummaryID
        ? collections.find(({ id }) => id == activeCollectionSummaryID)
        : undefined;
    return {
        selectedCollectionSummaryID: activeCollectionSummaryID,
        view: {
            type: "albums" as const,
            activeCollectionSummaryID: activeCollectionSummaryID ?? ALL_SECTION,
            activeCollection,
        },
    };
};

/**
 * Sibling of {@link deriveAlbumsViewAndSelectedID} for when we're in the hidden
 * albums section.
 */
const deriveHiddenAlbumsViewAndSelectedID = (
    hiddenCollections: GalleryState["hiddenCollections"],
    hiddenCollectionSummaries: GalleryState["hiddenCollectionSummaries"],
    selectedCollectionSummaryID: GalleryState["selectedCollectionSummaryID"],
) => {
    // Make sure that the last selected ID is still valid by searching for it.
    const activeCollectionSummaryID = selectedCollectionSummaryID
        ? hiddenCollectionSummaries.get(selectedCollectionSummaryID)?.id
        : undefined;
    const activeCollection = activeCollectionSummaryID
        ? hiddenCollections.find(({ id }) => id == activeCollectionSummaryID)
        : undefined;
    return {
        selectedCollectionSummaryID: activeCollectionSummaryID,
        view: {
            type: "hidden-albums" as const,
            activeCollectionSummaryID:
                activeCollectionSummaryID ?? HIDDEN_ITEMS_SECTION,
            activeCollection,
        },
    };
};

/**
 * Prune any entries for which we have newer remote data (as determined by their
 * presence in the given {@link updatedFiles}) from the given unsynced private
 * magic metadata {@link updates}.
 */
const prunedUnsyncedPrivateMagicMetadataUpdates = (
    updates: GalleryState["unsyncedPrivateMagicMetadataUpdates"],
    updatedFiles: EnteFile[],
) => {
    // Fastpath for happy case.
    if (updates.size == 0) return updates;

    const prunedUpdates = new Map(updates);
    for (const { id } of updatedFiles) prunedUpdates.delete(id);
    return prunedUpdates;
};

/**
 * Compute the {@link GalleryView} from its dependencies when we are switching
 * to (or back to) the "people" view.
 */
const derivePeopleView = (
    peopleState: GalleryState["peopleState"],
    tempDeletedFileIDs: GalleryState["tempDeletedFileIDs"],
    tempHiddenFileIDs: GalleryState["tempHiddenFileIDs"],
    selectedPersonID: GalleryState["selectedPersonID"],
    extraVisiblePerson: GalleryState["extraVisiblePerson"],
): {
    view: Extract<GalleryView, { type: "people" }>;
    extraVisiblePerson: GalleryState["extraVisiblePerson"];
} => {
    let people = peopleState?.people ?? [];
    let visiblePeople = peopleState?.visiblePeople ?? [];
    if (tempDeletedFileIDs.size + tempHiddenFileIDs.size > 0) {
        // Prune the in-memory temp updates from the actual state to
        // obtain the UI state. Kept inside an preflight check to so
        // that the common path remains fast.
        const filterTemp = (ps: Person[]) =>
            ps
                .map((p) => ({
                    ...p,
                    fileIDs: p.fileIDs.filter(
                        (id) =>
                            !tempDeletedFileIDs.has(id) &&
                            !tempHiddenFileIDs.has(id),
                    ),
                }))
                .filter((p) => p.fileIDs.length > 0);
        people = filterTemp(people);
        visiblePeople = filterTemp(visiblePeople);
    }

    // We might have an extraVisiblePerson that is now part of the visible ones
    // when the user un-ignores a person. If that's the case (which we can
    // detect by its absence from the list of underlying people, since its ID
    // would've changed), clear it out, otherwise we'll end up with two entries.
    if (extraVisiblePerson) {
        if (!people.find((p) => p.id == extraVisiblePerson?.id))
            extraVisiblePerson = undefined;
    }

    const findByIDIn = (ps: Person[]) =>
        ps.find((p) => p.id == selectedPersonID);
    let activePerson = findByIDIn(visiblePeople);
    if (!activePerson) {
        // This might be one of the normally hidden small clusters.
        activePerson = findByIDIn(people);
        if (activePerson) {
            // Temporarily add this person's entry to the list of people
            // surfaced in the people view.
            extraVisiblePerson = activePerson;
        } else {
            // We don't have an "All" pseudo-album in people view, so default to
            // the first person in the list (if any).
            activePerson = visiblePeople[0];
        }
    }

    const view = {
        type: "people" as const,
        visiblePeople: extraVisiblePerson
            ? visiblePeople.concat([extraVisiblePerson])
            : visiblePeople,
        activePerson,
    };

    return { view, extraVisiblePerson };
};

/**
 * Return a new state from the given {@link state} by recomputing all properties
 * that depend on normal (non-hidden) files, using the provided
 * {@link normalFiles}.
 *
 * Usually, we update state by manually dependency tracking on a fine grained
 * basis, but it results in a duplicate code when the files themselves change,
 * since they effect many things. This is a convenience function for updating
 * everything that needs to change when the normal files themselves change.
 */
const stateForUpdatedNormalFiles = (
    state: GalleryState,
    normalFiles: GalleryState["normalFiles"],
): GalleryState => ({
    ...state,
    normalFiles,
    archivedFileIDs: deriveArchivedFileIDs(
        state.archivedCollectionIDs,
        normalFiles,
    ),
    favoriteFileIDs: deriveFavoriteFileIDs(
        state.normalCollections,
        normalFiles,
        state.unsyncedFavoriteUpdates,
    ),
    fileNormalCollectionIDs: createFileCollectionIDs(normalFiles),
    normalCollectionSummaries: deriveNormalCollectionSummaries(
        state.user!,
        state.normalCollections,
        normalFiles,
        state.trashedFiles,
        state.archivedFileIDs,
    ),
    pendingSearchSuggestions: enqueuePendingSearchSuggestionsIfNeeded(
        state.searchSuggestion,
        state.pendingSearchSuggestions,
        state.isInSearchMode,
    ),
});

/**
 * Return a new state from the given {@link state} by recomputing all properties
 * that depend on hidden files, using the provided {@link hiddenFiles}.
 *
 * Usually, we update state by manually dependency tracking on a fine grained
 * basis, but it results in a duplicate code when the hidden files themselves
 * change, since they effect a few things. This is a convenience function for
 * updating everything that needs to change when the hidden files change.
 */
const stateForUpdatedHiddenFiles = (
    state: GalleryState,
    hiddenFiles: GalleryState["hiddenFiles"],
): GalleryState => ({
    ...state,
    hiddenFiles,
    hiddenFileIDs: deriveHiddenFileIDs(hiddenFiles),
    hiddenCollectionSummaries: deriveHiddenCollectionSummaries(
        state.user!,
        state.hiddenCollections,
        hiddenFiles,
    ),
});

/**
 * Return a new state by recomputing the {@link filteredFiles} property
 * depending on which view we are showing
 *
 * Usually, we update state by manually dependency tracking on a fine grained
 * basis, but it is cumbersome (and mistake prone) to do that for the list of
 * filtered files which depend on a many things. So this is a convenience
 * function for recomputing filtered files whenever any bit of the underlying
 * state that could affect the list of files changes.
 */
const stateByUpdatingFilteredFiles = (state: GalleryState) => {
    if (state.isInSearchMode) {
        const filteredFiles = state.searchResults ?? state.filteredFiles;
        return { ...state, filteredFiles };
    } else if (state.view?.type == "albums") {
        const filteredFiles = deriveAlbumsFilteredFiles(
            state.normalFiles,
            state.trashedFiles,
            state.hiddenFileIDs,
            state.archivedCollectionIDs,
            state.archivedFileIDs,
            state.tempDeletedFileIDs,
            state.tempHiddenFileIDs,
            state.view,
        );
        return { ...state, filteredFiles };
    } else if (state.view?.type == "hidden-albums") {
        const filteredFiles = deriveHiddenAlbumsFilteredFiles(
            state.hiddenFiles,
            state.defaultHiddenCollectionIDs,
            state.tempDeletedFileIDs,
            state.view,
        );
        return { ...state, filteredFiles };
    } else if (state.view?.type == "people") {
        const filteredFiles = derivePeopleFilteredFiles(
            state.normalFiles,
            state.view,
        );
        return { ...state, filteredFiles };
    } else {
        return state;
    }
};

/**
 * Compute the sorted list of files to show when we're in the "albums" view and
 * the dependencies change.
 */
const deriveAlbumsFilteredFiles = (
    normalFiles: GalleryState["normalFiles"],
    trashedFiles: GalleryState["trashedFiles"],
    hiddenFileIDs: GalleryState["hiddenFileIDs"],
    archivedCollectionIDs: GalleryState["archivedCollectionIDs"],
    archivedFileIDs: GalleryState["archivedFileIDs"],
    tempDeletedFileIDs: GalleryState["tempDeletedFileIDs"],
    tempHiddenFileIDs: GalleryState["tempHiddenFileIDs"],
    view: Extract<GalleryView, { type: "albums" | "hidden-albums" }>,
) => {
    const activeCollectionSummaryID = view.activeCollectionSummaryID;

    // Trash is dealt with separately.
    if (activeCollectionSummaryID === TRASH_SECTION) {
        return uniqueFilesByID([
            ...trashedFiles,
            ...normalFiles.filter((file) => tempDeletedFileIDs.has(file.id)),
        ]);
    }

    const filteredFiles = normalFiles.filter((file) => {
        if (tempDeletedFileIDs.has(file.id)) return false;
        if (hiddenFileIDs.has(file.id)) return false;
        if (tempHiddenFileIDs.has(file.id)) return false;

        // Archived files can only be seen in the archive section, or in their
        // respective collection.
        //
        // Note that a file may both be archived, AND be part of an archived
        // collection. Such files should be shown in both the archive section
        // and in their respective collection. Thus this (archived file) case
        // needs to be before the following (archived collection) case.
        if (isArchivedFile(file)) {
            return (
                activeCollectionSummaryID === ARCHIVE_SECTION ||
                activeCollectionSummaryID === file.collectionID
            );
        }

        // Files in archived collections can only be seen in their respective
        // collection.
        if (archivedCollectionIDs.has(file.collectionID)) {
            return activeCollectionSummaryID === file.collectionID;
        }

        if (activeCollectionSummaryID === ALL_SECTION) {
            // Archived files (whether individually archived, or part of some
            // archived album) should not be shown in "All".
            if (archivedFileIDs.has(file.id)) {
                return false;
            }
            // Show all remaining (non-hidden, non-archived) files in "All".
            return true;
        }

        // Show files that belong to the active collection.
        return activeCollectionSummaryID === file.collectionID;
    });

    return sortAndUniqueFilteredFiles(filteredFiles, view.activeCollection);
};

/**
 * Compute the sorted list of files to show when we're in the "hidden-albums"
 * view and the dependencies change.
 */
const deriveHiddenAlbumsFilteredFiles = (
    hiddenFiles: GalleryState["hiddenFiles"],
    defaultHiddenCollectionIDs: GalleryState["defaultHiddenCollectionIDs"],
    tempDeletedFileIDs: GalleryState["tempDeletedFileIDs"],
    view: Extract<GalleryView, { type: "albums" | "hidden-albums" }>,
) => {
    const activeCollectionSummaryID = view.activeCollectionSummaryID;
    const filteredFiles = hiddenFiles.filter((file) => {
        if (tempDeletedFileIDs.has(file.id)) return false;

        // "Hidden" shows all standalone hidden files.
        if (
            activeCollectionSummaryID === HIDDEN_ITEMS_SECTION &&
            defaultHiddenCollectionIDs.has(file.collectionID)
        ) {
            return true;
        }

        // Show files that belong to the active collection.
        return activeCollectionSummaryID === file.collectionID;
    });

    return sortAndUniqueFilteredFiles(filteredFiles, view.activeCollection);
};

/**
 * Prepare the list of files for being shown in the gallery.
 *
 * This functions uniques the given collection files so that there is only one
 * entry per file ID. Then it sorts them if the active collection prefers them
 * to be sorted oldest first (by default, lists of collection files are sorted
 * newest first, and we assume that {@link files} are already sorted that way).
 */
const sortAndUniqueFilteredFiles = (
    files: EnteFile[],
    activeCollection: Collection | undefined,
) => {
    const uniqueFiles = uniqueFilesByID(files);
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    const sortAsc = activeCollection?.pubMagicMetadata?.data?.asc ?? false;
    return sortAsc ? sortFiles(uniqueFiles, true) : uniqueFiles;
};

/**
 * Compute the sorted list of files to show when we're in the "people" view and
 * the dependencies change.
 */
const derivePeopleFilteredFiles = (
    normalFiles: GalleryState["normalFiles"],
    view: Extract<GalleryView, { type: "people" }>,
) => {
    const pfSet = new Set(view.activePerson?.fileIDs ?? []);
    return uniqueFilesByID(
        normalFiles.filter(({ id }) => {
            if (!pfSet.has(id)) return false;
            return true;
        }),
    );
};

/**
 * Trigger a recomputation of search results if needed.
 *
 * This convenience helper is used on updates to some state (collections, files)
 * that is used to derive the base set of files on which the search are
 * performed. It re-enqueues the current search suggestion as pending, which'll
 * trigger a recomputation of the state's {@link searchResults}.
 */
const enqueuePendingSearchSuggestionsIfNeeded = (
    searchSuggestion: GalleryState["searchSuggestion"],
    pendingSearchSuggestions: GalleryState["pendingSearchSuggestions"],
    isInSearchMode: GalleryState["isInSearchMode"],
) =>
    searchSuggestion && isInSearchMode
        ? [...pendingSearchSuggestions, searchSuggestion]
        : pendingSearchSuggestions;
