import { FILE_TYPE } from "@/media/file-type";
import { isNonWebImageFileExtension } from "@/media/formats";
import { heicToJPEG } from "@/media/heic-convert";
import { decodeLivePhoto } from "@/media/live-photo";
import {
    EncryptedEnteFile,
    EnteFile,
    FileMagicMetadata,
    FileMagicMetadataProps,
    FilePublicMagicMetadata,
    FilePublicMagicMetadataProps,
    FileWithUpdatedMagicMetadata,
} from "@/new/photos/types/file";
import { VISIBILITY_STATE } from "@/new/photos/types/magicMetadata";
import { lowercaseExtension } from "@/next/file";
import log from "@/next/log";
import { CustomErrorMessage, type Electron } from "@/next/types/ipc";
import { workerBridge } from "@/next/worker/worker-bridge";
import { withTimeout } from "@/utils/promise";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { User } from "@ente/shared/user/types";
import { downloadUsingAnchor } from "@ente/shared/utils";
import { t } from "i18next";
import isElectron from "is-electron";
import { moveToHiddenCollection } from "services/collectionService";
import { detectFileTypeInfo } from "services/detect-type";
import DownloadManager from "services/download";
import { updateFileCreationDateInEXIF } from "services/exif";
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
import { safeFileName } from "utils/native-fs";
import { writeStream } from "utils/native-stream";

const SUPPORTED_RAW_FORMATS = [
    "heic",
    "rw2",
    "tiff",
    "arw",
    "cr3",
    "cr2",
    "nef",
    "psd",
    "dng",
    "tif",
];

export enum FILE_OPS_TYPE {
    DOWNLOAD,
    FIX_TIME,
    ARCHIVE,
    UNARCHIVE,
    HIDE,
    TRASH,
    DELETE_PERMANENTLY,
}

class ModuleState {
    /**
     * This will be set to true if we get an error from the Node.js side of our
     * desktop app telling us that native JPEG conversion is not available for
     * the current OS/arch combination.
     *
     * That way, we can stop pestering it again and again (saving an IPC
     * round-trip).
     *
     * Note the double negative when it is used.
     */
    isNativeJPEGConversionNotAvailable = false;
}

const moduleState = new ModuleState();

/**
 * @returns a string to use as an identifier when logging information about the
 * given {@link enteFile}. The returned string contains the file name (for ease
 * of debugging) and the file ID (for exactness).
 */
export const fileLogID = (enteFile: EnteFile) =>
    `file ${enteFile.metadata.title ?? "-"} (${enteFile.id})`;

export async function getUpdatedEXIFFileForDownload(
    fileReader: FileReader,
    file: EnteFile,
    fileStream: ReadableStream<Uint8Array>,
): Promise<ReadableStream<Uint8Array>> {
    const extension = lowercaseExtension(file.metadata.title);
    if (
        file.metadata.fileType === FILE_TYPE.IMAGE &&
        file.pubMagicMetadata?.data.editedTime &&
        (extension == "jpeg" || extension == "jpg")
    ) {
        const fileBlob = await new Response(fileStream).blob();
        const updatedFileBlob = await updateFileCreationDateInEXIF(
            fileReader,
            fileBlob,
            new Date(file.pubMagicMetadata.data.editedTime / 1000),
        );
        return updatedFileBlob.stream();
    } else {
        return fileStream;
    }
}

export async function downloadFile(file: EnteFile) {
    try {
        const fileReader = new FileReader();
        let fileBlob = await new Response(
            await DownloadManager.getFile(file),
        ).blob();
        if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
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
                await getUpdatedEXIFFileForDownload(
                    fileReader,
                    file,
                    fileBlob.stream(),
                ),
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

export function sortTrashFiles(files: EnteFile[]) {
    return files.sort((a, b) => {
        if (a.deleteBy === b.deleteBy) {
            if (a.metadata.creationTime === b.metadata.creationTime) {
                return (
                    b.metadata.modificationTime - a.metadata.modificationTime
                );
            }
            return b.metadata.creationTime - a.metadata.creationTime;
        }
        return a.deleteBy - b.deleteBy;
    });
}

export async function decryptFile(
    file: EncryptedEnteFile,
    collectionKey: string,
): Promise<EnteFile> {
    try {
        const worker = await ComlinkCryptoWorker.getInstance();
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
        const fileMetadata = await worker.decryptMetadata(
            metadata.encryptedData,
            metadata.decryptionHeader,
            fileKey,
        );
        let fileMagicMetadata: FileMagicMetadata;
        let filePubMagicMetadata: FilePublicMagicMetadata;
        if (magicMetadata?.data) {
            fileMagicMetadata = {
                ...file.magicMetadata,
                data: await worker.decryptMetadata(
                    magicMetadata.data,
                    magicMetadata.header,
                    fileKey,
                ),
            };
        }
        if (pubMagicMetadata?.data) {
            filePubMagicMetadata = {
                ...pubMagicMetadata,
                data: await worker.decryptMetadata(
                    pubMagicMetadata.data,
                    pubMagicMetadata.header,
                    fileKey,
                ),
            };
        }
        return {
            ...restFileProps,
            key: fileKey,
            metadata: fileMetadata,
            magicMetadata: fileMagicMetadata,
            pubMagicMetadata: filePubMagicMetadata,
        };
    } catch (e) {
        log.error("file decryption failed", e);
        throw e;
    }
}

/**
 * The returned blob.type is filled in, whenever possible, with the MIME type of
 * the data that we're dealing with.
 */
export const getRenderableImage = async (fileName: string, imageBlob: Blob) => {
    try {
        const tempFile = new File([imageBlob], fileName);
        const fileTypeInfo = await detectFileTypeInfo(tempFile);
        log.debug(
            () =>
                `Need renderable image for ${JSON.stringify({ fileName, ...fileTypeInfo })}`,
        );
        const { extension } = fileTypeInfo;

        if (!isNonWebImageFileExtension(extension)) {
            // Either it is something that the browser already knows how to
            // render, or something we don't even about yet.
            const mimeType = fileTypeInfo.mimeType;
            if (!mimeType) {
                log.info(
                    "Trying to render a file without a MIME type",
                    fileName,
                );
                return imageBlob;
            } else {
                return new Blob([imageBlob], { type: mimeType });
            }
        }

        const available = !moduleState.isNativeJPEGConversionNotAvailable;
        if (isElectron() && available && isSupportedRawFormat(extension)) {
            // If we're running in our desktop app, see if our Node.js layer can
            // convert this into a JPEG using native tools for us.
            try {
                return await nativeConvertToJPEG(imageBlob);
            } catch (e) {
                if (e.message.endsWith(CustomErrorMessage.NotAvailable)) {
                    moduleState.isNativeJPEGConversionNotAvailable = true;
                } else {
                    log.error("Native conversion to JPEG failed", e);
                }
            }
        }

        if (extension == "heic" || extension == "heif") {
            // For HEIC/HEIF files we can use our web HEIC converter.
            return await heicToJPEG(imageBlob);
        }

        return undefined;
    } catch (e) {
        log.error(`Failed to get renderable image for ${fileName}`, e);
        return undefined;
    }
};

const nativeConvertToJPEG = async (imageBlob: Blob) => {
    const startTime = Date.now();
    const imageData = new Uint8Array(await imageBlob.arrayBuffer());
    const electron = globalThis.electron;
    // If we're running in a worker, we need to reroute the request back to
    // the main thread since workers don't have access to the `window` (and
    // thus, to the `window.electron`) object.
    const jpegData = electron
        ? await electron.convertToJPEG(imageData)
        : await workerBridge.convertToJPEG(imageData);
    log.debug(() => `Native JPEG conversion took ${Date.now() - startTime} ms`);
    return new Blob([jpegData], { type: "image/jpeg" });
};

export function isSupportedRawFormat(exactType: string) {
    return SUPPORTED_RAW_FORMATS.includes(exactType.toLowerCase());
}

export async function changeFilesVisibility(
    files: EnteFile[],
    visibility: VISIBILITY_STATE,
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

export async function changeFileCreationTime(
    file: EnteFile,
    editedTime: number,
): Promise<EnteFile> {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        editedTime,
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

/**
 * [Note: File name for local EnteFile objects]
 *
 * The title property in a file's metadata is the original file's name. The
 * metadata of a file cannot be edited. So if later on the file's name is
 * changed, then the edit is stored in the `editedName` property of the public
 * metadata of the file.
 *
 * This function merges these edits onto the file object that we use locally.
 * Effectively, post this step, the file's metadata.title can be used in lieu of
 * its filename.
 */
export function mergeMetadata(files: EnteFile[]): EnteFile[] {
    return files.map((file) => {
        if (file.pubMagicMetadata?.data.editedTime) {
            file.metadata.creationTime = file.pubMagicMetadata.data.editedTime;
        }
        if (file.pubMagicMetadata?.data.editedName) {
            file.metadata.title = file.pubMagicMetadata.data.editedName;
        }

        return file;
    });
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
    const fileReader = new FileReader();
    for (const file of files) {
        try {
            if (progressBarUpdater?.isCancelled()) {
                return;
            }
            await downloadFileDesktop(electron, fileReader, file, downloadPath);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            log.error("download fail for file", e);
            progressBarUpdater?.increaseFailed();
        }
    }
}

async function downloadFileDesktop(
    electron: Electron,
    fileReader: FileReader,
    file: EnteFile,
    downloadDir: string,
) {
    const fs = electron.fs;
    const stream = (await DownloadManager.getFile(
        file,
    )) as ReadableStream<Uint8Array>;
    const updatedStream = await getUpdatedEXIFFileForDownload(
        fileReader,
        file,
        stream,
    );

    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
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

export const isImageOrVideo = (fileType: FILE_TYPE) =>
    [FILE_TYPE.IMAGE, FILE_TYPE.VIDEO].includes(fileType);

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
            await changeFilesVisibility(files, VISIBILITY_STATE.ARCHIVED);
            break;
        case FILE_OPS_TYPE.UNARCHIVE:
            await changeFilesVisibility(files, VISIBILITY_STATE.VISIBLE);
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
