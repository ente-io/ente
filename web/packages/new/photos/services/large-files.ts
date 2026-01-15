import { ensureLocalUser } from "ente-accounts/services/user";
import { newID } from "ente-base/id";
import type { EnteFile } from "ente-media/file";
import { FileType } from "ente-media/file-type";
import { moveToTrash, savedNormalCollections } from "./collection";
import { savedCollectionFiles } from "./photos-fdb";
import { pullFiles } from "./pull";

/**
 * Minimum file size (in bytes) to be considered a "large" file.
 *
 * This matches the mobile implementation: 10 MB.
 */
export const MIN_LARGE_FILE_SIZE = 10 * 1024 * 1024;

/**
 * Filter type for large files.
 */
export type LargeFileFilter = "all" | "photos" | "videos";

/**
 * A large file as shown in the UI.
 */
export interface LargeFileItem {
    /**
     * A nanoid for this item.
     *
     * This can be used as the key when rendering the item in a list.
     */
    id: string;
    /**
     * The underlying file.
     */
    file: EnteFile;
    /**
     * The size of the file in bytes.
     */
    size: number;
    /**
     * `true` if the user has marked this item for deletion.
     */
    isSelected: boolean;
}

/**
 * Find files larger than {@link MIN_LARGE_FILE_SIZE} in the user's library.
 *
 * @param filter The type of files to include (all, photos, or videos).
 *
 * @returns An array of {@link LargeFileItem} sorted by file size (descending).
 */
export const findLargeFiles = async (
    filter: LargeFileFilter,
): Promise<LargeFileItem[]> => {
    const userID = ensureLocalUser().id;

    // Get collections owned by the user.
    const normalCollections = await savedNormalCollections();
    const normalOwnedCollections = normalCollections.filter(
        ({ owner }) => owner.id === userID,
    );
    const allowedCollectionIDs = new Set(
        normalOwnedCollections.map(({ id }) => id),
    );

    // Get all collection files.
    const collectionFiles = await savedCollectionFiles();

    // Track files we've already added (by file ID) to avoid duplicates
    // when the same file exists in multiple collections.
    const seenFileIDs = new Set<number>();
    const largeFiles: LargeFileItem[] = [];

    for (const file of collectionFiles) {
        // Skip files not in allowed collections.
        if (!allowedCollectionIDs.has(file.collectionID)) continue;

        // Skip files not owned by the user.
        if (file.ownerID !== userID) continue;

        // Skip files already processed (same file in different collection).
        if (seenFileIDs.has(file.id)) continue;

        // Get file size.
        const size = file.info?.fileSize;
        if (!size || size < MIN_LARGE_FILE_SIZE) continue;

        // Apply filter.
        if (!matchesFilter(file, filter)) continue;

        seenFileIDs.add(file.id);

        largeFiles.push({ id: newID("lf_"), file, size, isSelected: false });
    }

    // Sort by size descending (largest first).
    largeFiles.sort((a, b) => b.size - a.size);

    return largeFiles;
};

/**
 * Check if a file matches the given filter.
 */
const matchesFilter = (file: EnteFile, filter: LargeFileFilter): boolean => {
    switch (filter) {
        case "all":
            return true;
        case "photos":
            return (
                file.metadata.fileType === FileType.image ||
                file.metadata.fileType === FileType.livePhoto
            );
        case "videos":
            return file.metadata.fileType === FileType.video;
    }
};

/**
 * Delete selected large files by moving them to trash.
 *
 * @param largeFiles The list of large file items.
 * @param onProgress A function called with progress percentage (0-100).
 *
 * @returns A set of IDs of the items that were deleted.
 */
export const deleteSelectedLargeFiles = async (
    largeFiles: LargeFileItem[],
    onProgress: (progress: number) => void,
): Promise<Set<string>> => {
    const selectedItems = largeFiles.filter((item) => item.isSelected);
    const filesToTrash = selectedItems.map((item) => item.file);

    if (filesToTrash.length === 0) {
        return new Set();
    }

    let completedSteps = 0;
    const totalSteps = 2; // trash + sync
    const tickProgress = () =>
        onProgress((completedSteps++ / totalSteps) * 100);

    // Move files to trash.
    await moveToTrash(filesToTrash);
    tickProgress();

    // Sync local state.
    await pullFiles();
    tickProgress();

    return new Set(selectedItems.map((item) => item.id));
};

/**
 * Sort order for large files list.
 */
export type SortOrder = "desc" | "asc";

/**
 * State for the large files page.
 */
export interface LargeFilesState {
    /** Status of the analysis ("loading") process. */
    analysisStatus: undefined | "started" | "failed" | "completed";
    /**
     * List of large files.
     *
     * These are sorted by file size based on sortOrder.
     */
    largeFiles: LargeFileItem[];
    /**
     * The current filter for file types.
     */
    filter: LargeFileFilter;
    /**
     * The current sort order (descending = largest first, ascending = smallest first).
     */
    sortOrder: SortOrder;
    /**
     * The number of files currently selected for deletion.
     */
    selectedCount: number;
    /**
     * The total size (in bytes) of files currently selected for deletion.
     */
    selectedSize: number;
    /**
     * If a deletion is in progress, this will indicate its progress
     * percentage (a number between 0 and 100).
     */
    deleteProgress: number | undefined;
    /**
     * Set of selected file IDs (the underlying EnteFile.id).
     * Used to persist selection across filter changes.
     */
    selectedFileIDs: Set<number>;
}

/**
 * Actions for the large files reducer.
 */
export type LargeFilesAction =
    | { type: "analyze" }
    | { type: "analysisFailed" }
    | { type: "analysisCompleted"; largeFiles: LargeFileItem[] }
    | { type: "changeFilter"; filter: LargeFileFilter }
    | { type: "changeSortOrder"; sortOrder: SortOrder }
    | { type: "toggleSelection"; index: number }
    | { type: "deselectAll" }
    | { type: "selectAll" }
    | { type: "delete" }
    | { type: "setDeleteProgress"; progress: number }
    | { type: "deleteFailed" }
    | { type: "deleteCompleted"; removedIDs: Set<string> };

/**
 * Initial state for the large files reducer.
 */
export const largeFilesInitialState: LargeFilesState = {
    analysisStatus: undefined,
    largeFiles: [],
    filter: "all",
    sortOrder: "desc",
    selectedCount: 0,
    selectedSize: 0,
    deleteProgress: undefined,
    selectedFileIDs: new Set(),
};

/**
 * Reducer for the large files page state.
 */
export const largeFilesReducer = (
    state: LargeFilesState,
    action: LargeFilesAction,
): LargeFilesState => {
    switch (action.type) {
        case "analyze":
            return { ...state, analysisStatus: "started" };
        case "analysisFailed":
            return { ...state, analysisStatus: "failed" };
        case "analysisCompleted": {
            // Restore selection state from selectedFileIDs
            const selectedFileIDs = state.selectedFileIDs;
            const filesWithSelection = action.largeFiles.map((item) => ({
                ...item,
                isSelected: selectedFileIDs.has(item.file.id),
            }));
            // Sort according to current sort order (findLargeFiles always returns desc)
            const largeFiles = sortedCopyOfLargeFiles(
                filesWithSelection,
                state.sortOrder,
            );
            const { selectedCount, selectedSize } =
                computeSelectedCountAndSize(largeFiles);
            return {
                ...state,
                analysisStatus: "completed",
                largeFiles,
                selectedCount,
                selectedSize,
            };
        }

        case "changeFilter": {
            // No-op if filter hasn't actually changed
            if (action.filter === state.filter) {
                return state;
            }
            // Block filter changes during deletion to prevent state corruption
            if (state.deleteProgress !== undefined) {
                return state;
            }
            // Preserve selectedFileIDs when filter changes
            return {
                ...largeFilesInitialState,
                filter: action.filter,
                sortOrder: state.sortOrder,
                selectedFileIDs: state.selectedFileIDs,
            };
        }

        case "changeSortOrder": {
            // Block sort order changes during deletion
            if (state.deleteProgress !== undefined) {
                return state;
            }
            const sortOrder = action.sortOrder;
            const largeFiles = sortedCopyOfLargeFiles(
                state.largeFiles,
                sortOrder,
            );
            return { ...state, sortOrder, largeFiles };
        }

        case "toggleSelection": {
            const index = action.index;
            // Bounds check to prevent crashes
            if (index < 0 || index >= state.largeFiles.length) {
                return state;
            }
            const item = state.largeFiles[index]!;
            const newIsSelected = !item.isSelected;
            // Create new array with immutably updated item
            const largeFiles = state.largeFiles.map((file, i) =>
                i === index ? { ...file, isSelected: newIsSelected } : file,
            );
            // Update selectedFileIDs
            const selectedFileIDs = new Set(state.selectedFileIDs);
            if (newIsSelected) {
                selectedFileIDs.add(item.file.id);
            } else {
                selectedFileIDs.delete(item.file.id);
            }
            const { selectedCount, selectedSize } =
                computeSelectedCountAndSize(largeFiles);
            return {
                ...state,
                largeFiles,
                selectedCount,
                selectedSize,
                selectedFileIDs,
            };
        }

        case "deselectAll": {
            // Only deselect currently visible items, preserve selections for
            // items not in the current filtered view
            const visibleFileIDs = new Set(
                state.largeFiles.map((item) => item.file.id),
            );
            const selectedFileIDs = new Set<number>();
            for (const id of state.selectedFileIDs) {
                if (!visibleFileIDs.has(id)) {
                    selectedFileIDs.add(id);
                }
            }
            const largeFiles = state.largeFiles.map((item) => ({
                ...item,
                isSelected: false,
            }));
            return {
                ...state,
                largeFiles,
                selectedCount: 0,
                selectedSize: 0,
                selectedFileIDs,
            };
        }

        case "selectAll": {
            // Add currently visible items to selection, preserve existing
            // selections from other filtered views
            const largeFiles = state.largeFiles.map((item) => ({
                ...item,
                isSelected: true,
            }));
            const selectedFileIDs = new Set(state.selectedFileIDs);
            for (const item of largeFiles) {
                selectedFileIDs.add(item.file.id);
            }
            const { selectedCount, selectedSize } =
                computeSelectedCountAndSize(largeFiles);
            return {
                ...state,
                largeFiles,
                selectedCount,
                selectedSize,
                selectedFileIDs,
            };
        }

        case "delete":
            return { ...state, deleteProgress: 0 };

        case "setDeleteProgress":
            return { ...state, deleteProgress: action.progress };

        case "deleteFailed":
            return { ...state, deleteProgress: undefined };

        case "deleteCompleted": {
            // Single pass: filter files and collect removed file IDs
            const largeFiles: LargeFileItem[] = [];
            const removedFileIDs = new Set<number>();
            for (const item of state.largeFiles) {
                if (action.removedIDs.has(item.id)) {
                    removedFileIDs.add(item.file.id);
                } else {
                    largeFiles.push(item);
                }
            }
            // Filter selectedFileIDs removing deleted ones
            const selectedFileIDs = new Set<number>();
            for (const id of state.selectedFileIDs) {
                if (!removedFileIDs.has(id)) {
                    selectedFileIDs.add(id);
                }
            }
            const { selectedCount, selectedSize } =
                computeSelectedCountAndSize(largeFiles);
            return {
                ...state,
                largeFiles,
                selectedCount,
                selectedSize,
                deleteProgress: undefined,
                selectedFileIDs,
            };
        }
    }
};

const computeSelectedCountAndSize = (largeFiles: LargeFileItem[]) => {
    const selectedCount = largeFiles.reduce(
        (sum, { isSelected }) => sum + (isSelected ? 1 : 0),
        0,
    );
    const selectedSize = largeFiles.reduce(
        (sum, { size, isSelected }) => sum + (isSelected ? size : 0),
        0,
    );
    return { selectedCount, selectedSize };
};

const sortedCopyOfLargeFiles = (
    largeFiles: LargeFileItem[],
    sortOrder: SortOrder,
) =>
    [...largeFiles].sort((a, b) =>
        sortOrder === "desc" ? b.size - a.size : a.size - b.size,
    );
