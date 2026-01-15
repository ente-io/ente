import type { GalleryBarMode } from "ente-new/photos/components/gallery/reducer";
import {
    PseudoCollectionID,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";

/**
 * Actions that can be performed on files via the context menu.
 *
 * These correspond to the same operations available in SelectedFileOptions.
 */
export type FileContextAction =
    | "download"
    | "fixTime"
    | "favorite"
    | "archive"
    | "unarchive"
    | "hide"
    | "unhide"
    | "trash"
    | "deletePermanently"
    | "restore"
    | "addToAlbum"
    | "moveToAlbum"
    | "removeFromAlbum"
    | "addPerson";

/**
 * Context needed to determine which file actions should be available.
 */
export interface FileActionContext {
    /** The current bar mode (albums, hidden-albums, people). */
    barMode?: GalleryBarMode;
    /** Whether we're in search mode. */
    isInSearchMode: boolean;
    /**
     * The collection summary for the current view.
     *
     * Will be undefined if we're in people section or showing search results.
     */
    collectionSummary: CollectionSummary | undefined;
    /**
     * Whether to show the "Add Person" action.
     *
     * This depends on ML being enabled and having named people.
     */
    showAddPerson: boolean;
}

/**
 * Returns the list of available file actions based on the current context.
 *
 * This function encapsulates the conditional logic from SelectedFileOptions
 * to enable reuse in both the selection bar and the context menu.
 */
export function getAvailableFileActions(
    context: FileActionContext,
): FileContextAction[] {
    const { barMode, isInSearchMode, collectionSummary, showAddPerson } =
        context;

    const actions = getBaseActions(barMode, isInSearchMode, collectionSummary);

    // Insert "addPerson" before modification actions if enabled
    // (not applicable for trash since you can't add people to trashed files)
    if (showAddPerson && collectionSummary?.id !== PseudoCollectionID.trash) {
        insertAddPersonBeforeModifications(actions);
    }

    return actions;
}

/**
 * Returns base actions without the "addPerson" action.
 */
function getBaseActions(
    barMode: GalleryBarMode | undefined,
    isInSearchMode: boolean,
    collectionSummary: CollectionSummary | undefined,
): FileContextAction[] {
    // Search mode actions
    if (isInSearchMode) {
        return [
            "favorite",
            "fixTime",
            "download",
            "addToAlbum",
            "archive",
            "hide",
            "trash",
        ];
    }

    // People mode actions
    if (barMode === "people") {
        return [
            "favorite",
            "download",
            "addToAlbum",
            "archive",
            "hide",
            "trash",
        ];
    }

    // Trash actions
    if (collectionSummary?.id === PseudoCollectionID.trash) {
        return ["restore", "deletePermanently"];
    }

    // Uncategorized actions
    if (collectionSummary?.attributes.has("uncategorized")) {
        return ["download", "moveToAlbum", "trash"];
    }

    // Shared incoming actions
    if (collectionSummary?.attributes.has("sharedIncoming")) {
        return ["download", "removeFromAlbum"];
    }

    // Hidden albums mode actions
    if (barMode === "hidden-albums") {
        return ["download", "unhide", "trash"];
    }

    // Default (normal albums) actions
    const isUserFavorites =
        !!collectionSummary?.attributes.has("userFavorites");
    const isArchiveItems =
        collectionSummary?.id === PseudoCollectionID.archiveItems;

    const actions: FileContextAction[] = [];

    // Favorite button only shown when not in favorites and not in archive
    if (!isUserFavorites && !isArchiveItems) {
        actions.push("favorite");
    }

    actions.push("fixTime", "download", "addToAlbum");

    if (collectionSummary?.id === PseudoCollectionID.all) {
        actions.push("archive");
    } else if (isArchiveItems) {
        actions.push("unarchive");
    } else if (!isUserFavorites) {
        actions.push("moveToAlbum", "removeFromAlbum");
    }

    actions.push("hide", "trash");

    return actions;
}

/**
 * Actions that modify file visibility or location.
 * "addPerson" is inserted before the first of these actions.
 */
const modificationActions: FileContextAction[] = [
    "archive",
    "unarchive",
    "hide",
    "unhide",
    "trash",
    "moveToAlbum",
    "removeFromAlbum",
];

/**
 * Inserts "addPerson" before the first modification action in the array.
 */
function insertAddPersonBeforeModifications(
    actions: FileContextAction[],
): void {
    const insertIndex = actions.findIndex((a) =>
        modificationActions.includes(a),
    );
    if (insertIndex !== -1) {
        actions.splice(insertIndex, 0, "addPerson");
    } else {
        actions.push("addPerson");
    }
}
