import { useCallback, useState } from "react";

/**
 * An object that keeps track of progress of a user-initiated download of a set
 * of files to the user's device.
 *
 * This "download" is distinct from the downloads the app does from remote (e.g.
 * when the user is viewing them).
 *
 * What we're doing here is perhaps more accurately described "a user initiated
 * download of files to the user's device", but that is too long, so we instead
 * refer to this process as "saving them".
 *
 * Note however that the app's UI itself takes the user perspective, so the
 * upper (UI) layers use the word "download", while this implementation layer
 * uses the word "save", and there is an unavoidable incongruity in the middle.
 */
export interface SaveGroup {
    /**
     * A randomly generated unique identifier of this set of saves.
     */
    id: number;
    /**
     * The user visible title of the save group.
     *
     * Depending on the context can either be an auto generated string (e.g "5
     * files"), or the name of the collection which is being downloaded.
     */
    title: string;
    /**
     * If this save group is associated with a {@link CollectionSummary}, then
     * the ID of that collection summary.
     *
     * The {@link SaveGroup} type is also used in the context of the albums app,
     * which does not use or need the concept of link {@link CollectionSummary},
     * we to avoid taking a dependency of the type we store these two relevant
     * properties - {@link collectionSummaryID} and
     * {@link isHiddenCollectionSummary} - inline.
     */
    collectionSummaryID?: number;
    /**
     * `true` if the collection summary associated with the save group is
     * hidden.
     */
    isHiddenCollectionSummary?: boolean;
    /**
     * The path to a directory on the user's file system that was selected by
     * the user to save the files in when they initiated the download on the
     * desktop app.
     *
     * This property is only set when running in the context of the desktop app.
     * The web app downloads to the user's default downloads folder, and when
     * running in the web app this property will not be set.
     */
    downloadDirPath?: string;
    /**
     * The total number of files to save to the user's device.
     */
    total: number;
    /**
     * The number of files that have been saved so far.
     */
    success: number;
    /**
     * The number of failures.
     */
    failed: number;
    /**
     * An {@link AbortController} that can be used to cancel the save.
     */
    canceller: AbortController;
}

/**
 * Return `true` if there are no files in this save group that are pending.
 */
export const isSaveComplete = ({ total, success, failed }: SaveGroup) =>
    total == success + failed;

/**
 * Return `true` if there are no files in this save group that are pending, but
 * one or more files had failed to download.
 */
export const isSaveCompleteWithErrors = (group: SaveGroup) =>
    group.failed > 0 && isSaveComplete(group);

/**
 * Return `true` if this save was cancelled on a user request.
 */
export const isSaveCancelled = (group: SaveGroup) =>
    group.canceller.signal.aborted;

/**
 * A function that can be used to add a save group.
 *
 * It returns a function that can subsequently be used to update the save group
 * by applying a transform to it (see {@link UpdateSaveGroup}). The UI will
 * react and update itself on updates done this way.
 */
export type AddSaveGroup = (
    group: Pick<
        SaveGroup,
        | "title"
        | "collectionSummaryID"
        | "isHiddenCollectionSummary"
        | "downloadDirPath"
        | "total"
        | "canceller"
    >,
) => UpdateSaveGroup;

/**
 * A function that can be used to update a instance of a save group by applying
 * the provided transform.
 *
 * This is obtained by a call to an instance of {@link AddSaveGroup}. The UI
 * will update itself to reflect the changes made by the transform.
 */
export type UpdateSaveGroup = (
    tranform: (prev: SaveGroup) => SaveGroup,
) => void;

/**
 * A function that can be used to remove a save group.
 *
 * Save groups can be removed both on user actions - if the user presses the
 * close button to discard the notification showing the status of the save group
 * (cancelling it if needed) - or programmatically, if it is found that there
 * are no files that need saving for a particular request.
 */
export type RemoveSaveGroup = (saveGroup: SaveGroup) => void;

/**
 * A custom React hook that manages a list of active {@link SaveGroup}s, and
 * provides functions to add and remove entries to the list.
 */
export const useSaveGroups = () => {
    const [saveGroups, setSaveGroups] = useState<SaveGroup[]>([]);

    const handleAddSaveGroup: AddSaveGroup = useCallback((saveGroup) => {
        const id = Math.random();
        setSaveGroups((groups) => [
            ...groups,
            { ...saveGroup, id, success: 0, failed: 0 },
        ]);
        return (tx: (group: SaveGroup) => SaveGroup) => {
            setSaveGroups((groups) =>
                groups.map((g) => (g.id == id ? tx(g) : g)),
            );
        };
    }, []);

    const handleRemoveSaveGroup: RemoveSaveGroup = useCallback(
        ({ id }) => setSaveGroups((groups) => groups.filter((g) => g.id != id)),
        [],
    );

    return {
        saveGroups,
        onAddSaveGroup: handleAddSaveGroup,
        onRemoveSaveGroup: handleRemoveSaveGroup,
    };
};
