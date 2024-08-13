import { sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { type Electron } from "@/base/types/ipc";
import { ItemVisibility } from "@/media/file-metadata";
import { FileType } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import DownloadManager from "@/new/photos/services/download";
import { updateExifIfNeededAndPossible } from "@/new/photos/services/exif-update";
import {
    EncryptedEnteFile,
    EnteFile,
    FileMagicMetadata,
    FileMagicMetadataProps,
    FilePublicMagicMetadata,
    FilePublicMagicMetadataProps,
    FileWithUpdatedMagicMetadata,
} from "@/new/photos/types/file";
import { detectFileTypeInfo } from "@/new/photos/utils/detect-type";
import { mergeMetadata } from "@/new/photos/utils/file";
import { safeFileName } from "@/new/photos/utils/native-fs";
import { writeStream } from "@/new/photos/utils/native-stream";
import { withTimeout } from "@/utils/promise";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import { downloadUsingAnchor } from "@ente/shared/utils";
import { t } from "i18next";
import { moveToHiddenCollection } from "services/collectionService";
import {
    deleteFromTrash,
    trashFiles,
    updateFileMagicMetadata,
    updateFilePublicMagicMetadata,
} from "services/fileService";
import {
    SelectedState,
    SetFilesDownloadProgressAttributes,
    SetFilesDownloadProgressAttributesCreator,
} from "types/gallery";
import { isArchivedFile, updateMagicMetadata } from "utils/magicMetadata";

export enum FILE_OPS_TYPE {
    DOWNLOAD,
    FIX_TIME,
    ARCHIVE,
    UNARCHIVE,
    HIDE,
    TRASH,
    DELETE_PERMANENTLY,
}

export async function downloadFile(file: EnteFile) {
    try {
        let fileBlob = await new Response(
            await DownloadManager.getFile(file),
        ).blob();
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
            downloadUsingAnchor(tempImageURL, imageFileName);
            downloadUsingAnchor(tempVideoURL, videoFileName);
        } else {
            const fileType = await detectFileTypeInfo(
                new File([fileBlob], file.metadata.title),
            );
            fileBlob = await new Response(
                await updateExifIfNeededAndPossible(file, fileBlob.stream()),
            ).blob();
            fileBlob = new Blob([fileBlob], { type: fileType.mimeType });
            const tempURL = URL.createObjectURL(fileBlob);
            downloadUsingAnchor(tempURL, file.metadata.title);
        }
    } catch (e) {
        log.error("failed to download file", e);
        throw e;
    }
}

/** Segment the given {@link files} into lists indexed by their collection ID */
export const groupFilesBasedOnCollectionID = (files: EnteFile[]) => {
    const result = new Map<number, EnteFile[]>();
    for (const file of files) {
        const id = file.collectionID;
        if (!result.has(id)) result.set(id, []);
        result.get(id).push(file);
    }
    return result;
};

function getSelectedFileIds(selectedFiles: SelectedState) {
    const filesIDs: number[] = [];
    for (const [key, val] of Object.entries(selectedFiles)) {
        if (typeof val === "boolean" && val) {
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

export function sortFiles(files: EnteFile[], sortAsc = false) {
    // sort based on the time of creation time of the file,
    // for files with same creation time, sort based on the time of last modification
    const factor = sortAsc ? -1 : 1;
    return files.sort((a, b) => {
        if (a.metadata.creationTime === b.metadata.creationTime) {
            return (
                factor *
                (b.metadata.modificationTime - a.metadata.modificationTime)
            );
        }
        return factor * (b.metadata.creationTime - a.metadata.creationTime);
    });
}

export async function decryptFile(
    file: EncryptedEnteFile,
    collectionKey: string,
): Promise<EnteFile> {
    try {
        const worker = await sharedCryptoWorker();
        const {
            encryptedKey,
            keyDecryptionNonce,
            metadata,
            magicMetadata,
            pubMagicMetadata,
            ...restFileProps
        } = file;
        const fileKey = await worker.decryptB64(
            encryptedKey,
            keyDecryptionNonce,
            collectionKey,
        );
        const fileMetadata = await worker.decryptMetadataJSON({
            encryptedDataB64: metadata.encryptedData,
            decryptionHeaderB64: metadata.decryptionHeader,
            keyB64: fileKey,
        });
        let fileMagicMetadata: FileMagicMetadata;
        let filePubMagicMetadata: FilePublicMagicMetadata;
        if (magicMetadata?.data) {
            fileMagicMetadata = {
                ...file.magicMetadata,
                data: await worker.decryptMetadataJSON({
                    encryptedDataB64: magicMetadata.data,
                    decryptionHeaderB64: magicMetadata.header,
                    keyB64: fileKey,
                }),
            };
        }
        if (pubMagicMetadata?.data) {
            filePubMagicMetadata = {
                ...pubMagicMetadata,
                data: await worker.decryptMetadataJSON({
                    encryptedDataB64: pubMagicMetadata.data,
                    decryptionHeaderB64: pubMagicMetadata.header,
                    keyB64: fileKey,
                }),
            };
        }
        return {
            ...restFileProps,
            key: fileKey,
            // @ts-expect-error TODO: Need to use zod here.
            metadata: fileMetadata,
            magicMetadata: fileMagicMetadata,
            pubMagicMetadata: filePubMagicMetadata,
        };
    } catch (e) {
        log.error("file decryption failed", e);
        throw e;
    }
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

export async function changeFileName(
    file: EnteFile,
    editedName: string,
): Promise<EnteFile> {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        editedName,
    };

    const updatedPublicMagicMetadata: FilePublicMagicMetadata =
        await updateMagicMetadata(
            updatedPublicMagicMetadataProps,
            file.pubMagicMetadata,
            file.key,
        );
    const updateResult = await updateFilePublicMagicMetadata([
        { file, updatedPublicMagicMetadata },
    ]);
    return updateResult[0];
}

export async function changeCaption(
    file: EnteFile,
    caption: string,
): Promise<EnteFile> {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        caption,
    };

    const updatedPublicMagicMetadata: FilePublicMagicMetadata =
        await updateMagicMetadata(
            updatedPublicMagicMetadataProps,
            file.pubMagicMetadata,
            file.key,
        );
    const updateResult = await updateFilePublicMagicMetadata([
        { file, updatedPublicMagicMetadata },
    ]);
    return updateResult[0];
}

export function isSharedFile(user: User, file: EnteFile) {
    if (!user?.id || !file?.ownerID) {
        return false;
    }
    return file.ownerID !== user.id;
}

export function updateExistingFilePubMetadata(
    existingFile: EnteFile,
    updatedFile: EnteFile,
) {
    existingFile.pubMagicMetadata = updatedFile.pubMagicMetadata;
    existingFile.metadata = mergeMetadata([existingFile])[0].metadata;
}

export async function getFileFromURL(fileURL: string, name: string) {
    const fileBlob = await (await fetch(fileURL)).blob();
    const fileFile = new File([fileBlob], name);
    return fileFile;
}

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

    const stream = await DownloadManager.getFile(file);
    const updatedStream = await updateExifIfNeededAndPossible(file, stream);

    if (file.metadata.fileType === FileType.livePhoto) {
        const fileBlob = await new Response(updatedStream).blob();
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
            `${downloadDir}/${imageExportName}`,
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
                `${downloadDir}/${videoExportName}`,
                videoStream,
            );
        } catch (e) {
            await fs.rm(`${downloadDir}/${imageExportName}`);
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
            `${downloadDir}/${fileExportName}`,
            updatedStream,
        );
    }
}

export const isImageOrVideo = (fileType: FileType) =>
    [FileType.image, FileType.video].includes(fileType);

export const getArchivedFiles = (files: EnteFile[]) => {
    return files.filter(isArchivedFile).map((file) => file.id);
};

export const createTypedObjectURL = async (blob: Blob, fileName: string) => {
    const type = await detectFileTypeInfo(new File([blob], fileName));
    return URL.createObjectURL(new Blob([blob], { type: type.mimeType }));
};

export const getUserOwnedFiles = (files: EnteFile[]) => {
    const user: User = getData(LS_KEYS.USER);
    if (!user?.id) {
        throw Error("user missing");
    }
    return files.filter((file) => file.ownerID === user.id);
};

// doesn't work on firefox
export const copyFileToClipboard = async (fileURL: string) => {
    const canvas = document.createElement("canvas");
    const canvasCTX = canvas.getContext("2d");
    const image = new Image();

    const blobPromise = new Promise<Blob>((resolve, reject) => {
        try {
            image.setAttribute("src", fileURL);
            image.onload = () => {
                canvas.width = image.width;
                canvas.height = image.height;
                canvasCTX.drawImage(image, 0, 0, image.width, image.height);
                canvas.toBlob(
                    (blob) => {
                        resolve(blob);
                    },
                    "image/png",
                    1,
                );
            };
        } catch (e) {
            log.error("Failed to copy to clipboard", e);
            reject(e);
        }
    });

    const blob = await withTimeout(blobPromise, 30 * 1000);

    const { ClipboardItem } = window;
    await navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
};

export function getLatestVersionFiles(files: EnteFile[]) {
    const latestVersionFiles = new Map<string, EnteFile>();
    files.forEach((file) => {
        const uid = `${file.collectionID}-${file.id}`;
        if (
            !latestVersionFiles.has(uid) ||
            latestVersionFiles.get(uid).updationTime < file.updationTime
        ) {
            latestVersionFiles.set(uid, file);
        }
    });
    return Array.from(latestVersionFiles.values()).filter(
        (file) => !file.isDeleted,
    );
}

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

export function constructFileToCollectionMap(files: EnteFile[]) {
    const fileToCollectionsMap = new Map<number, number[]>();
    (files ?? []).forEach((file) => {
        if (!fileToCollectionsMap.get(file.id)) {
            fileToCollectionsMap.set(file.id, []);
        }
        fileToCollectionsMap.get(file.id).push(file.collectionID);
    });
    return fileToCollectionsMap;
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

export const handleFileOps = async (
    ops: FILE_OPS_TYPE,
    files: EnteFile[],
    setTempDeletedFileIds: (
        tempDeletedFileIds: Set<number> | ((prev: Set<number>) => Set<number>),
    ) => void,
    setTempHiddenFileIds: (
        tempHiddenFileIds: Set<number> | ((prev: Set<number>) => Set<number>),
    ) => void,
    setFixCreationTimeAttributes: (
        fixCreationTimeAttributes:
            | {
                  files: EnteFile[];
              }
            | ((prev: { files: EnteFile[] }) => { files: EnteFile[] }),
    ) => void,
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator,
) => {
    switch (ops) {
        case FILE_OPS_TYPE.TRASH:
            await deleteFileHelper(files, false, setTempDeletedFileIds);
            break;
        case FILE_OPS_TYPE.DELETE_PERMANENTLY:
            await deleteFileHelper(files, true, setTempDeletedFileIds);
            break;
        case FILE_OPS_TYPE.HIDE:
            await hideFilesHelper(files, setTempHiddenFileIds);
            break;
        case FILE_OPS_TYPE.DOWNLOAD: {
            const setSelectedFileDownloadProgressAttributes =
                setFilesDownloadProgressAttributesCreator(
                    `${files.length} ${t("FILES")}`,
                );
            await downloadSelectedFiles(
                files,
                setSelectedFileDownloadProgressAttributes,
            );
            break;
        }
        case FILE_OPS_TYPE.FIX_TIME:
            fixTimeHelper(files, setFixCreationTimeAttributes);
            break;
        case FILE_OPS_TYPE.ARCHIVE:
            await changeFilesVisibility(files, ItemVisibility.archived);
            break;
        case FILE_OPS_TYPE.UNARCHIVE:
            await changeFilesVisibility(files, ItemVisibility.visible);
            break;
    }
};

const deleteFileHelper = async (
    selectedFiles: EnteFile[],
    permanent: boolean,
    setTempDeletedFileIds: (
        tempDeletedFileIds: Set<number> | ((prev: Set<number>) => Set<number>),
    ) => void,
) => {
    try {
        setTempDeletedFileIds((deletedFileIds) => {
            selectedFiles.forEach((file) => deletedFileIds.add(file.id));
            return new Set(deletedFileIds);
        });
        if (permanent) {
            await deleteFromTrash(selectedFiles.map((file) => file.id));
        } else {
            await trashFiles(selectedFiles);
        }
    } catch (e) {
        setTempDeletedFileIds(new Set());
        throw e;
    }
};

const hideFilesHelper = async (
    selectedFiles: EnteFile[],
    setTempHiddenFileIds: (
        tempHiddenFileIds: Set<number> | ((prev: Set<number>) => Set<number>),
    ) => void,
) => {
    try {
        setTempHiddenFileIds((hiddenFileIds) => {
            selectedFiles.forEach((file) => hiddenFileIds.add(file.id));
            return new Set(hiddenFileIds);
        });
        await moveToHiddenCollection(selectedFiles);
    } catch (e) {
        setTempHiddenFileIds(new Set());
        throw e;
    }
};

const fixTimeHelper = async (
    selectedFiles: EnteFile[],
    setFixCreationTimeAttributes: (fixCreationTimeAttributes: {
        files: EnteFile[];
    }) => void,
) => {
    setFixCreationTimeAttributes({ files: selectedFiles });
};
