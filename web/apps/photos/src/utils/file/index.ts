import { joinPath } from "ente-base/file-name";
import log from "ente-base/log";
import { type Electron } from "ente-base/types/ipc";
import { downloadAndRevokeObjectURL } from "ente-base/utils/web";
import { downloadManager } from "ente-gallery/services/download";
import { updateFileMagicMetadata } from "ente-gallery/services/file";
import { updateMagicMetadata } from "ente-gallery/services/magic-metadata";
import { detectFileTypeInfo } from "ente-gallery/utils/detect-type";
import { writeStream } from "ente-gallery/utils/native-stream";
import {
    EnteFile,
    FileMagicMetadataProps,
    FileWithUpdatedMagicMetadata,
} from "ente-media/file";
import { ItemVisibility, isArchivedFile } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { decodeLivePhoto } from "ente-media/live-photo";
import {
    deleteFromTrash,
    moveToTrash,
} from "ente-new/photos/services/collection";
import { safeFileName } from "ente-new/photos/utils/native-fs";
import { getData } from "ente-shared/storage/localStorage";
import type { User } from "ente-shared/user/types";
import { t } from "i18next";
import {
    addMultipleToFavorites,
    moveToHiddenCollection,
} from "services/collectionService";
import {
    SelectedState,
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";

export type FileOp =
    | "download"
    | "fixTime"
    | "favorite"
    | "archive"
    | "unarchive"
    | "hide"
    | "trash"
    | "deletePermanently";

export async function downloadFile(file: EnteFile) {
    try {
        let fileBlob = await downloadManager.fileBlob(file);
        if (file.metadata.fileType === FileType.livePhoto) {
            const { imageFileName, imageData, videoFileName, videoData } =
                await decodeLivePhoto(file.metadata.title, fileBlob);
            const image = new File([imageData], imageFileName);
            const imageType = await detectFileTypeInfo(image);
            const tempImageURL = URL.createObjectURL(
                new Blob([imageData], { type: imageType.mimeType }),
            );
            const video = new File([videoData], videoFileName);
            const videoType = await detectFileTypeInfo(video);
            const tempVideoURL = URL.createObjectURL(
                new Blob([videoData], { type: videoType.mimeType }),
            );
            downloadAndRevokeObjectURL(tempImageURL, imageFileName);
            downloadAndRevokeObjectURL(tempVideoURL, videoFileName);
        } else {
            const fileType = await detectFileTypeInfo(
                new File([fileBlob], file.metadata.title),
            );
            fileBlob = new Blob([fileBlob], { type: fileType.mimeType });
            const tempURL = URL.createObjectURL(fileBlob);
            downloadAndRevokeObjectURL(tempURL, file.metadata.title);
        }
    } catch (e) {
        log.error("failed to download file", e);
        throw e;
    }
}

function getSelectedFileIds(selectedFiles: SelectedState) {
    const filesIDs: number[] = [];
    for (const [key, val] of Object.entries(selectedFiles)) {
        if (typeof val == "boolean" && val) {
            filesIDs.push(Number(key));
        }
    }
    return new Set(filesIDs);
}
export function getSelectedFiles(
    selected: SelectedState,
    files: EnteFile[],
): EnteFile[] {
    const selectedFilesIDs = getSelectedFileIds(selected);
    return files.filter((file) => selectedFilesIDs.has(file.id));
}

export async function changeFilesVisibility(
    files: EnteFile[],
    visibility: ItemVisibility,
): Promise<EnteFile[]> {
    const fileWithUpdatedMagicMetadataList: FileWithUpdatedMagicMetadata[] = [];
    for (const file of files) {
        const updatedMagicMetadataProps: FileMagicMetadataProps = {
            visibility,
        };

        fileWithUpdatedMagicMetadataList.push({
            file,
            updatedMagicMetadata: await updateMagicMetadata(
                updatedMagicMetadataProps,
                file.magicMetadata,
                file.key,
            ),
        });
    }
    return await updateFileMagicMetadata(fileWithUpdatedMagicMetadataList);
}

export function isSharedFile(user: User, file: EnteFile) {
    if (!user?.id || !file?.ownerID) {
        return false;
    }
    return file.ownerID !== user.id;
}

export async function getFileFromURL(fileURL: string, name: string) {
    const fileBlob = await (await fetch(fileURL)).blob();
    const fileFile = new File([fileBlob], name);
    return fileFile;
}

export async function downloadFilesWithProgress(
    files: EnteFile[],
    downloadDirPath: string,
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    if (!files.length) {
        return;
    }
    const canceller = new AbortController();
    const increaseSuccess = () => {
        if (canceller.signal.aborted) return;
        setFilesDownloadProgressAttributes((prev) => ({
            ...prev,
            success: prev.success + 1,
        }));
    };
    const increaseFailed = () => {
        if (canceller.signal.aborted) return;
        setFilesDownloadProgressAttributes((prev) => ({
            ...prev,
            failed: prev.failed + 1,
        }));
    };
    const isCancelled = () => canceller.signal.aborted;

    setFilesDownloadProgressAttributes({
        downloadDirPath,
        success: 0,
        failed: 0,
        total: files.length,
        canceller,
    });

    const electron = globalThis.electron;
    if (electron) {
        await downloadFilesDesktop(
            electron,
            files,
            { increaseSuccess, increaseFailed, isCancelled },
            downloadDirPath,
        );
    } else {
        await downloadFiles(files, {
            increaseSuccess,
            increaseFailed,
            isCancelled,
        });
    }
}

export async function downloadSelectedFiles(
    files: EnteFile[],
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    if (!files.length) {
        return;
    }
    let downloadDirPath: string;
    const electron = globalThis.electron;
    if (electron) {
        downloadDirPath = await electron.selectDirectory();
        if (!downloadDirPath) {
            return;
        }
    }
    await downloadFilesWithProgress(
        files,
        downloadDirPath,
        setFilesDownloadProgressAttributes,
    );
}

export async function downloadSingleFile(
    file: EnteFile,
    setFilesDownloadProgressAttributes: SetFilesDownloadProgressAttributes,
) {
    let downloadDirPath: string;
    const electron = globalThis.electron;
    if (electron) {
        downloadDirPath = await electron.selectDirectory();
        if (!downloadDirPath) {
            return;
        }
    }
    await downloadFilesWithProgress(
        [file],
        downloadDirPath,
        setFilesDownloadProgressAttributes,
    );
}

export async function downloadFiles(
    files: EnteFile[],
    progressBarUpdater: {
        increaseSuccess: () => void;
        increaseFailed: () => void;
        isCancelled: () => boolean;
    },
) {
    for (const file of files) {
        try {
            if (progressBarUpdater?.isCancelled()) {
                return;
            }
            await downloadFile(file);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            log.error("download fail for file", e);
            progressBarUpdater?.increaseFailed();
        }
    }
}

async function downloadFilesDesktop(
    electron: Electron,
    files: EnteFile[],
    progressBarUpdater: {
        increaseSuccess: () => void;
        increaseFailed: () => void;
        isCancelled: () => boolean;
    },
    downloadPath: string,
) {
    for (const file of files) {
        try {
            if (progressBarUpdater?.isCancelled()) {
                return;
            }
            await downloadFileDesktop(electron, file, downloadPath);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            log.error("download fail for file", e);
            progressBarUpdater?.increaseFailed();
        }
    }
}

async function downloadFileDesktop(
    electron: Electron,
    file: EnteFile,
    downloadDir: string,
) {
    const fs = electron.fs;

    const stream = await downloadManager.fileStream(file);

    if (file.metadata.fileType === FileType.livePhoto) {
        const fileBlob = await new Response(stream).blob();
        const { imageFileName, imageData, videoFileName, videoData } =
            await decodeLivePhoto(file.metadata.title, fileBlob);
        const imageExportName = await safeFileName(
            downloadDir,
            imageFileName,
            fs.exists,
        );
        const imageStream = new Response(imageData).body;
        await writeStream(
            electron,
            joinPath(downloadDir, imageExportName),
            imageStream,
        );
        try {
            const videoExportName = await safeFileName(
                downloadDir,
                videoFileName,
                fs.exists,
            );
            const videoStream = new Response(videoData).body;
            await writeStream(
                electron,
                joinPath(downloadDir, videoExportName),
                videoStream,
            );
        } catch (e) {
            await fs.rm(joinPath(downloadDir, imageExportName));
            throw e;
        }
    } else {
        const fileExportName = await safeFileName(
            downloadDir,
            file.metadata.title,
            fs.exists,
        );
        await writeStream(
            electron,
            joinPath(downloadDir, fileExportName),
            stream,
        );
    }
}

export const isImageOrVideo = (fileType: FileType) =>
    fileType == FileType.image || fileType == FileType.video;

export const getArchivedFiles = (files: EnteFile[]) => {
    return files.filter(isArchivedFile).map((file) => file.id);
};

export const createTypedObjectURL = async (blob: Blob, fileName: string) => {
    const type = await detectFileTypeInfo(new File([blob], fileName));
    return URL.createObjectURL(new Blob([blob], { type: type.mimeType }));
};

export const getUserOwnedFiles = (files: EnteFile[]) => {
    const user: User = getData("user");
    if (!user?.id) {
        throw Error("user missing");
    }
    return files.filter((file) => file.ownerID === user.id);
};

export function getPersonalFiles(
    files: EnteFile[],
    user: User,
    collectionIdToOwnerIDMap?: Map<number, number>,
) {
    if (!user?.id) {
        throw Error("user missing");
    }
    return files.filter(
        (file) =>
            file.ownerID === user.id &&
            (!collectionIdToOwnerIDMap ||
                collectionIdToOwnerIDMap.get(file.collectionID) === user.id),
    );
}

export function getIDBasedSortedFiles(files: EnteFile[]) {
    return files.sort((a, b) => a.id - b.id);
}

export const shouldShowAvatar = (file: EnteFile, user: User) => {
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

export const handleFileOp = async (
    op: FileOp,
    files: EnteFile[],
    markTempDeleted: (files: EnteFile[]) => void,
    clearTempDeleted: () => void,
    markTempHidden: (files: EnteFile[]) => void,
    clearTempHidden: () => void,
    fixCreationTime: (files: EnteFile[]) => void,
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator,
) => {
    switch (op) {
        case "download": {
            const setSelectedFileDownloadProgressAttributes =
                setFilesDownloadProgressAttributesCreator(
                    t("files_count", { count: files.length }),
                );
            await downloadSelectedFiles(
                files,
                setSelectedFileDownloadProgressAttributes,
            );
            break;
        }
        case "fixTime":
            fixCreationTime(files);
            break;
        case "favorite":
            await addMultipleToFavorites(files);
            break;
        case "archive":
            await changeFilesVisibility(files, ItemVisibility.archived);
            break;
        case "unarchive":
            await changeFilesVisibility(files, ItemVisibility.visible);
            break;
        case "hide":
            try {
                markTempHidden(files);
                await moveToHiddenCollection(files);
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
