import type { LocalUser } from "ente-accounts/services/user";
import type { AddSaveGroup } from "ente-gallery/components/utils/save-groups";
import { saveFiles } from "ente-gallery/services/save";
import type { EnteFile } from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";
import { type FileOp } from "ente-new/photos/components/SelectedFileOptions";
import {
    addToFavoritesCollection,
    deleteFromTrash,
    hideFiles,
    moveToTrash,
} from "ente-new/photos/services/collection";
import { updateFilesVisibility } from "ente-new/photos/services/file";
import type { SelectedState } from "types/gallery";

export function getSelectedFiles(
    selected: SelectedState,
    files: EnteFile[],
): EnteFile[] {
    const selectedFilesIDs = new Set<number>();
    for (const [key, val] of Object.entries(selected)) {
        if (typeof val == "boolean" && val) {
            selectedFilesIDs.add(Number(key));
        }
    }

    return files.filter((file) => selectedFilesIDs.has(file.id));
}

export const shouldShowAvatar = (
    file: EnteFile,
    user: LocalUser | undefined,
) => {
    if (!file || !user) {
        return false;
    }
    // is Shared file
    else if (file.ownerID !== user.id) {
        return true;
    }
    // is public collected file
    else if (
        file.ownerID === user.id &&
        file.pubMagicMetadata?.data?.uploaderName
    ) {
        return true;
    } else {
        return false;
    }
};

export const performFileOp = async (
    op: FileOp,
    files: EnteFile[],
    onAddSaveGroup: AddSaveGroup,
    markTempDeleted: (files: EnteFile[]) => void,
    clearTempDeleted: () => void,
    markTempHidden: (files: EnteFile[]) => void,
    clearTempHidden: () => void,
    fixCreationTime: (files: EnteFile[]) => void,
) => {
    switch (op) {
        case "download": {
            await saveFiles(files, onAddSaveGroup);
            break;
        }
        case "fixTime":
            fixCreationTime(files);
            break;
        case "favorite":
            await addToFavoritesCollection(files);
            break;
        case "archive":
            await updateFilesVisibility(files, ItemVisibility.archived);
            break;
        case "unarchive":
            await updateFilesVisibility(files, ItemVisibility.visible);
            break;
        case "hide":
            try {
                markTempHidden(files);
                await hideFiles(files);
            } catch (e) {
                clearTempHidden();
                throw e;
            }
            break;
        case "trash":
            try {
                markTempDeleted(files);
                await moveToTrash(files);
            } catch (e) {
                clearTempDeleted();
                throw e;
            }
            break;
        case "deletePermanently":
            try {
                markTempDeleted(files);
                await deleteFromTrash(files.map((file) => file.id));
            } catch (e) {
                clearTempDeleted();
                throw e;
            }
            break;
    }
};
