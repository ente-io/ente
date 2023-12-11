import { SelectedState } from 'types/gallery';
import {
    EnteFile,
    EncryptedEnteFile,
    FileWithUpdatedMagicMetadata,
    FileMagicMetadata,
    FileMagicMetadataProps,
    FilePublicMagicMetadata,
    FilePublicMagicMetadataProps,
} from 'types/file';
import { decodeLivePhoto } from 'services/livePhotoService';
import { getFileType } from 'services/typeDetectionService';
import DownloadManager, {
    LivePhotoSourceURL,
    SourceURLs,
} from 'services/download';
import { logError } from '@ente/shared/sentry';
import { User } from '@ente/shared/user/types';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import { updateFileCreationDateInEXIF } from 'services/upload/exifService';
import {
    TYPE_JPEG,
    TYPE_JPG,
    TYPE_HEIC,
    TYPE_HEIF,
    FILE_TYPE,
    SUPPORTED_RAW_FORMATS,
    RAW_FORMATS,
} from 'constants/file';
import heicConversionService from 'services/heicConversionService';
import * as ffmpegService from 'services/ffmpeg/ffmpegService';
import { VISIBILITY_STATE } from 'types/magicMetadata';
import { isArchivedFile, updateMagicMetadata } from 'utils/magicMetadata';

import { addLocalLog, addLogLine } from '@ente/shared/logging';
import { CustomError } from '@ente/shared/error';
import { convertBytesToHumanReadable } from '@ente/shared/utils/size';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import {
    deleteFromTrash,
    trashFiles,
    updateFileMagicMetadata,
    updateFilePublicMagicMetadata,
} from 'services/fileService';
import isElectron from 'is-electron';
import { isPlaybackPossible } from 'utils/photoFrame';
import { FileTypeInfo } from 'types/upload';
import { moveToHiddenCollection } from 'services/collectionService';

import ElectronFSService from '@ente/shared/electron';
import { getFileExportPath, getUniqueFileExportName } from 'utils/export';
import imageProcessor from 'services/imageProcessor';
import ElectronAPIs from '@ente/shared/electron';
import { downloadUsingAnchor } from '@ente/shared/utils';

const WAIT_TIME_IMAGE_CONVERSION = 30 * 1000;

export enum FILE_OPS_TYPE {
    DOWNLOAD,
    FIX_TIME,
    ARCHIVE,
    UNARCHIVE,
    HIDE,
    TRASH,
    DELETE_PERMANENTLY,
}

export async function getUpdatedEXIFFileForDownload(
    fileReader: FileReader,
    file: EnteFile,
    fileStream: ReadableStream<Uint8Array>
): Promise<ReadableStream<Uint8Array>> {
    const extension = getFileExtension(file.metadata.title);
    if (
        file.metadata.fileType === FILE_TYPE.IMAGE &&
        file.pubMagicMetadata?.data.editedTime &&
        (extension === TYPE_JPEG || extension === TYPE_JPG)
    ) {
        const fileBlob = await new Response(fileStream).blob();
        const updatedFileBlob = await updateFileCreationDateInEXIF(
            fileReader,
            fileBlob,
            new Date(file.pubMagicMetadata.data.editedTime / 1000)
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
            await DownloadManager.getFile(file)
        ).blob();
        if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
            const livePhoto = await decodeLivePhoto(file, fileBlob);
            const image = new File([livePhoto.image], livePhoto.imageNameTitle);
            const imageType = await getFileType(image);
            const tempImageURL = URL.createObjectURL(
                new Blob([livePhoto.image], { type: imageType.mimeType })
            );
            const video = new File([livePhoto.video], livePhoto.videoNameTitle);
            const videoType = await getFileType(video);
            const tempVideoURL = URL.createObjectURL(
                new Blob([livePhoto.video], { type: videoType.mimeType })
            );
            downloadUsingAnchor(tempImageURL, livePhoto.imageNameTitle);
            downloadUsingAnchor(tempVideoURL, livePhoto.videoNameTitle);
        } else {
            const fileType = await getFileType(
                new File([fileBlob], file.metadata.title)
            );
            fileBlob = await new Response(
                await getUpdatedEXIFFileForDownload(
                    fileReader,
                    file,
                    fileBlob.stream()
                )
            ).blob();
            fileBlob = new Blob([fileBlob], { type: fileType.mimeType });
            const tempURL = URL.createObjectURL(fileBlob);
            downloadUsingAnchor(tempURL, file.metadata.title);
        }
    } catch (e) {
        logError(e, 'failed to download file');
        throw e;
    }
}

export function groupFilesBasedOnCollectionID(files: EnteFile[]) {
    const collectionWiseFiles = new Map<number, EnteFile[]>();
    for (const file of files) {
        if (!collectionWiseFiles.has(file.collectionID)) {
            collectionWiseFiles.set(file.collectionID, []);
        }
        collectionWiseFiles.get(file.collectionID).push(file);
    }
    return collectionWiseFiles;
}

function getSelectedFileIds(selectedFiles: SelectedState) {
    const filesIDs: number[] = [];
    for (const [key, val] of Object.entries(selectedFiles)) {
        if (typeof val === 'boolean' && val) {
            filesIDs.push(Number(key));
        }
    }
    return new Set(filesIDs);
}
export function getSelectedFiles(
    selected: SelectedState,
    files: EnteFile[]
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
    collectionKey: string
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
            collectionKey
        );
        const fileMetadata = await worker.decryptMetadata(
            metadata.encryptedData,
            metadata.decryptionHeader,
            fileKey
        );
        let fileMagicMetadata: FileMagicMetadata;
        let filePubMagicMetadata: FilePublicMagicMetadata;
        if (magicMetadata?.data) {
            fileMagicMetadata = {
                ...file.magicMetadata,
                data: await worker.decryptMetadata(
                    magicMetadata.data,
                    magicMetadata.header,
                    fileKey
                ),
            };
        }
        if (pubMagicMetadata?.data) {
            filePubMagicMetadata = {
                ...pubMagicMetadata,
                data: await worker.decryptMetadata(
                    pubMagicMetadata.data,
                    pubMagicMetadata.header,
                    fileKey
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
        logError(e, 'file decryption failed');
        throw e;
    }
}

export function getFileNameWithoutExtension(filename: string) {
    const lastDotPosition = filename.lastIndexOf('.');
    if (lastDotPosition === -1) return filename;
    else return filename.slice(0, lastDotPosition);
}

export function getFileExtensionWithDot(filename: string) {
    const lastDotPosition = filename.lastIndexOf('.');
    if (lastDotPosition === -1) return '';
    else return filename.slice(lastDotPosition);
}

export function splitFilenameAndExtension(filename: string): [string, string] {
    const lastDotPosition = filename.lastIndexOf('.');
    if (lastDotPosition === -1) return [filename, null];
    else
        return [
            filename.slice(0, lastDotPosition),
            filename.slice(lastDotPosition + 1),
        ];
}

export function getFileExtension(filename: string) {
    return splitFilenameAndExtension(filename)[1]?.toLocaleLowerCase();
}

export function generateStreamFromArrayBuffer(data: Uint8Array) {
    return new ReadableStream({
        async start(controller: ReadableStreamDefaultController) {
            controller.enqueue(data);
            controller.close();
        },
    });
}

export async function getRenderableFileURL(
    file: EnteFile,
    fileBlob: Blob,
    originalFileURL: string,
    forceConvert: boolean
): Promise<SourceURLs> {
    let srcURLs: SourceURLs['url'];
    switch (file.metadata.fileType) {
        case FILE_TYPE.IMAGE: {
            const convertedBlob = await getRenderableImage(
                file.metadata.title,
                fileBlob
            );
            const convertedURL = getFileObjectURL(
                originalFileURL,
                fileBlob,
                convertedBlob
            );
            srcURLs = convertedURL;
            break;
        }
        case FILE_TYPE.LIVE_PHOTO: {
            srcURLs = await getRenderableLivePhotoURL(
                file,
                fileBlob,
                forceConvert
            );
            break;
        }
        case FILE_TYPE.VIDEO: {
            const convertedBlob = await getPlayableVideo(
                file.metadata.title,
                fileBlob,
                forceConvert
            );
            const convertedURL = getFileObjectURL(
                originalFileURL,
                fileBlob,
                convertedBlob
            );
            srcURLs = convertedURL;
            break;
        }
        default: {
            srcURLs = originalFileURL;
            break;
        }
    }

    let isOriginal: boolean;
    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        isOriginal = false;
    } else {
        isOriginal = (srcURLs as string) === (originalFileURL as string);
    }

    return {
        url: srcURLs,
        isOriginal,
        isRenderable:
            file.metadata.fileType !== FILE_TYPE.LIVE_PHOTO && !!srcURLs,
        type:
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
                ? 'livePhoto'
                : 'normal',
    };
}

async function getRenderableLivePhotoURL(
    file: EnteFile,
    fileBlob: Blob,
    forceConvert: boolean
): Promise<LivePhotoSourceURL> {
    const livePhoto = await decodeLivePhoto(file, fileBlob);

    const getRenderableLivePhotoImageURL = async () => {
        try {
            const imageBlob = new Blob([livePhoto.image]);
            const convertedImageBlob = await getRenderableImage(
                livePhoto.imageNameTitle,
                imageBlob
            );

            return URL.createObjectURL(convertedImageBlob);
        } catch (e) {
            //ignore and return null
            return null;
        }
    };

    const getRenderableLivePhotoVideoURL = async () => {
        try {
            const videoBlob = new Blob([livePhoto.video]);

            const convertedVideoBlob = await getPlayableVideo(
                livePhoto.videoNameTitle,
                videoBlob,
                forceConvert,
                true
            );
            return URL.createObjectURL(convertedVideoBlob);
        } catch (e) {
            //ignore and return null
            return null;
        }
    };

    return {
        image: getRenderableLivePhotoImageURL,
        video: getRenderableLivePhotoVideoURL,
    };
}

export async function getPlayableVideo(
    videoNameTitle: string,
    videoBlob: Blob,
    forceConvert = false,
    runOnWeb = false
) {
    try {
        const isPlayable = await isPlaybackPossible(
            URL.createObjectURL(videoBlob)
        );
        if (isPlayable && !forceConvert) {
            return videoBlob;
        } else {
            if (!forceConvert && !runOnWeb && !isElectron()) {
                return null;
            }
            addLogLine(
                'video format not supported, converting it name:',
                videoNameTitle
            );
            const mp4ConvertedVideo = await ffmpegService.convertToMP4(
                new File([videoBlob], videoNameTitle)
            );
            addLogLine('video successfully converted', videoNameTitle);
            return new Blob([await mp4ConvertedVideo.arrayBuffer()]);
        }
    } catch (e) {
        addLogLine('video conversion failed', videoNameTitle);
        logError(e, 'video conversion failed');
        return null;
    }
}

export async function getRenderableImage(fileName: string, imageBlob: Blob) {
    let fileTypeInfo: FileTypeInfo;
    try {
        const tempFile = new File([imageBlob], fileName);
        fileTypeInfo = await getFileType(tempFile);
        addLocalLog(() => `file type info: ${JSON.stringify(fileTypeInfo)}`);
        const { exactType } = fileTypeInfo;
        let convertedImageBlob: Blob;
        if (isRawFile(exactType)) {
            try {
                if (!isSupportedRawFormat(exactType)) {
                    throw Error(CustomError.UNSUPPORTED_RAW_FORMAT);
                }

                if (!isElectron()) {
                    throw Error(CustomError.NOT_AVAILABLE_ON_WEB);
                }
                addLogLine(
                    `RawConverter called for ${fileName}-${convertBytesToHumanReadable(
                        imageBlob.size
                    )}`
                );
                convertedImageBlob = await imageProcessor.convertToJPEG(
                    imageBlob,
                    fileName
                );
                addLogLine(`${fileName} successfully converted`);
            } catch (e) {
                try {
                    if (!isFileHEIC(exactType)) {
                        throw e;
                    }
                    addLogLine(
                        `HEICConverter called for ${fileName}-${convertBytesToHumanReadable(
                            imageBlob.size
                        )}`
                    );
                    convertedImageBlob = await heicConversionService.convert(
                        imageBlob
                    );
                    addLogLine(`${fileName} successfully converted`);
                } catch (e) {
                    throw Error(CustomError.NON_PREVIEWABLE_FILE);
                }
            }
            return convertedImageBlob;
        } else {
            return imageBlob;
        }
    } catch (e) {
        logError(e, 'get Renderable Image failed', { fileTypeInfo });
        return null;
    }
}

export function isFileHEIC(exactType: string) {
    return (
        exactType.toLowerCase().endsWith(TYPE_HEIC) ||
        exactType.toLowerCase().endsWith(TYPE_HEIF)
    );
}

export function isRawFile(exactType: string) {
    return RAW_FORMATS.includes(exactType.toLowerCase());
}

export function isSupportedRawFormat(exactType: string) {
    return SUPPORTED_RAW_FORMATS.includes(exactType.toLowerCase());
}

export async function changeFilesVisibility(
    files: EnteFile[],
    visibility: VISIBILITY_STATE
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
                file.key
            ),
        });
    }
    return await updateFileMagicMetadata(fileWithUpdatedMagicMetadataList);
}

export async function changeFileCreationTime(
    file: EnteFile,
    editedTime: number
): Promise<EnteFile> {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        editedTime,
    };
    const updatedPublicMagicMetadata: FilePublicMagicMetadata =
        await updateMagicMetadata(
            updatedPublicMagicMetadataProps,
            file.pubMagicMetadata,
            file.key
        );
    const updateResult = await updateFilePublicMagicMetadata([
        { file, updatedPublicMagicMetadata },
    ]);
    return updateResult[0];
}

export async function changeFileName(
    file: EnteFile,
    editedName: string
): Promise<EnteFile> {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        editedName,
    };

    const updatedPublicMagicMetadata: FilePublicMagicMetadata =
        await updateMagicMetadata(
            updatedPublicMagicMetadataProps,
            file.pubMagicMetadata,
            file.key
        );
    const updateResult = await updateFilePublicMagicMetadata([
        { file, updatedPublicMagicMetadata },
    ]);
    return updateResult[0];
}

export async function changeCaption(
    file: EnteFile,
    caption: string
): Promise<EnteFile> {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        caption,
    };

    const updatedPublicMagicMetadata: FilePublicMagicMetadata =
        await updateMagicMetadata(
            updatedPublicMagicMetadataProps,
            file.pubMagicMetadata,
            file.key
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
    updatedFile: EnteFile
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

export async function downloadFiles(
    files: EnteFile[],
    progressBarUpdater?: {
        increaseSuccess: () => void;
        increaseFailed: () => void;
        isCancelled: () => boolean;
    }
) {
    for (const file of files) {
        try {
            if (progressBarUpdater?.isCancelled()) {
                return;
            }
            await downloadFile(file);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            logError(e, 'download fail for file');
            progressBarUpdater?.increaseFailed();
        }
    }
}

export async function downloadFilesDesktop(
    files: EnteFile[],
    progressBarUpdater: {
        increaseSuccess: () => void;
        increaseFailed: () => void;
        isCancelled: () => boolean;
    },
    downloadPath: string
) {
    const fileReader = new FileReader();
    for (const file of files) {
        try {
            if (progressBarUpdater?.isCancelled()) {
                return;
            }
            await downloadFileDesktop(fileReader, file, downloadPath);
            progressBarUpdater?.increaseSuccess();
        } catch (e) {
            logError(e, 'download fail for file');
            progressBarUpdater?.increaseFailed();
        }
    }
}

export async function downloadFileDesktop(
    fileReader: FileReader,
    file: EnteFile,
    downloadPath: string
) {
    const fileStream = (await DownloadManager.getFile(
        file
    )) as ReadableStream<Uint8Array>;
    const updatedFileStream = await getUpdatedEXIFFileForDownload(
        fileReader,
        file,
        fileStream
    );

    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        const fileBlob = await new Response(updatedFileStream).blob();
        const livePhoto = await decodeLivePhoto(file, fileBlob);
        const imageExportName = getUniqueFileExportName(
            downloadPath,
            livePhoto.imageNameTitle
        );
        const imageStream = generateStreamFromArrayBuffer(livePhoto.image);
        await ElectronAPIs.saveStreamToDisk(
            getFileExportPath(downloadPath, imageExportName),
            imageStream
        );
        try {
            const videoExportName = getUniqueFileExportName(
                downloadPath,
                livePhoto.videoNameTitle
            );
            const videoStream = generateStreamFromArrayBuffer(livePhoto.video);
            await ElectronAPIs.saveStreamToDisk(
                getFileExportPath(downloadPath, videoExportName),
                videoStream
            );
        } catch (e) {
            ElectronFSService.deleteFile(
                getFileExportPath(downloadPath, imageExportName)
            );
            throw e;
        }
    } else {
        const fileExportName = getUniqueFileExportName(
            downloadPath,
            file.metadata.title
        );
        await ElectronAPIs.saveStreamToDisk(
            getFileExportPath(downloadPath, fileExportName),
            updatedFileStream
        );
    }
}

export const isImageOrVideo = (fileType: FILE_TYPE) =>
    [FILE_TYPE.IMAGE, FILE_TYPE.VIDEO].includes(fileType);

export const getArchivedFiles = (files: EnteFile[]) => {
    return files.filter(isArchivedFile).map((file) => file.id);
};

export const createTypedObjectURL = async (blob: Blob, fileName: string) => {
    const type = await getFileType(new File([blob], fileName));
    return URL.createObjectURL(new Blob([blob], { type: type.mimeType }));
};

export const getUserOwnedFiles = (files: EnteFile[]) => {
    const user: User = getData(LS_KEYS.USER);
    if (!user?.id) {
        throw Error('user missing');
    }
    return files.filter((file) => file.ownerID === user.id);
};

// doesn't work on firefox
export const copyFileToClipboard = async (fileUrl: string) => {
    const canvas = document.createElement('canvas');
    const canvasCTX = canvas.getContext('2d');
    const image = new Image();

    const blobPromise = new Promise<Blob>((resolve, reject) => {
        let timeout: NodeJS.Timeout = null;
        try {
            image.setAttribute('src', fileUrl);
            image.onload = () => {
                canvas.width = image.width;
                canvas.height = image.height;
                canvasCTX.drawImage(image, 0, 0, image.width, image.height);
                canvas.toBlob(
                    (blob) => {
                        resolve(blob);
                    },
                    'image/png',
                    1
                );

                clearTimeout(timeout);
            };
        } catch (e) {
            void logError(e, 'failed to copy to clipboard');
            reject(e);
        } finally {
            clearTimeout(timeout);
        }
        timeout = setTimeout(
            () => reject(Error(CustomError.WAIT_TIME_EXCEEDED)),
            WAIT_TIME_IMAGE_CONVERSION
        );
    });

    const { ClipboardItem } = window;

    await navigator.clipboard
        .write([new ClipboardItem({ 'image/png': blobPromise })])
        .catch((e) => logError(e, 'failed to copy to clipboard'));
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
        (file) => !file.isDeleted
    );
}

export function getPersonalFiles(
    files: EnteFile[],
    user: User,
    collectionIdToOwnerIDMap?: Map<number, number>
) {
    if (!user?.id) {
        throw Error('user missing');
    }
    return files.filter(
        (file) =>
            file.ownerID === user.id &&
            (!collectionIdToOwnerIDMap ||
                collectionIdToOwnerIDMap.get(file.collectionID) === user.id)
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
    setDeletedFileIds: (
        deletedFileIds: Set<number> | ((prev: Set<number>) => Set<number>)
    ) => void,
    setHiddenFileIds: (
        hiddenFileIds: Set<number> | ((prev: Set<number>) => Set<number>)
    ) => void,
    setFixCreationTimeAttributes: (
        fixCreationTimeAttributes:
            | {
                  files: EnteFile[];
              }
            | ((prev: { files: EnteFile[] }) => { files: EnteFile[] })
    ) => void
) => {
    switch (ops) {
        case FILE_OPS_TYPE.TRASH:
            await deleteFileHelper(files, false, setDeletedFileIds);
            break;
        case FILE_OPS_TYPE.DELETE_PERMANENTLY:
            await deleteFileHelper(files, true, setDeletedFileIds);
            break;
        case FILE_OPS_TYPE.HIDE:
            await hideFilesHelper(files, setHiddenFileIds);
            break;
        case FILE_OPS_TYPE.DOWNLOAD:
            await downloadFiles(files);
            break;
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
    setDeletedFileIds: (
        deletedFileIds: Set<number> | ((prev: Set<number>) => Set<number>)
    ) => void
) => {
    try {
        setDeletedFileIds((deletedFileIds) => {
            selectedFiles.forEach((file) => deletedFileIds.add(file.id));
            return new Set(deletedFileIds);
        });
        if (permanent) {
            await deleteFromTrash(selectedFiles.map((file) => file.id));
        } else {
            await trashFiles(selectedFiles);
        }
    } catch (e) {
        setDeletedFileIds(new Set());
        throw e;
    }
};

const hideFilesHelper = async (
    selectedFiles: EnteFile[],
    setHiddenFileIds: (
        hiddenFileIds: Set<number> | ((prev: Set<number>) => Set<number>)
    ) => void
) => {
    try {
        setHiddenFileIds((hiddenFileIds) => {
            selectedFiles.forEach((file) => hiddenFileIds.add(file.id));
            return new Set(hiddenFileIds);
        });
        await moveToHiddenCollection(selectedFiles);
    } catch (e) {
        setHiddenFileIds(new Set());
        throw e;
    }
};

const fixTimeHelper = async (
    selectedFiles: EnteFile[],
    setFixCreationTimeAttributes: (fixCreationTimeAttributes: {
        files: EnteFile[];
    }) => void
) => {
    setFixCreationTimeAttributes({ files: selectedFiles });
};

const getFileObjectURL = (
    originalFileURL: string,
    originalBlob: Blob,
    convertedBlob: Blob
) => {
    const convertedURL = convertedBlob
        ? convertedBlob === originalBlob
            ? originalFileURL
            : URL.createObjectURL(convertedBlob)
        : null;
    return convertedURL;
};

export const getStreamLength = async (stream: ReadableStream<Uint8Array>) => {
    const reader = stream.getReader();
    let length = 0;

    // eslint-disable-next-line no-constant-condition
    while (true) {
        const { done, value } = await reader.read();
        if (done) {
            break;
        }
        length += value.length;
    }
    return length;
};
