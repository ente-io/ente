import { SelectedState } from 'types/gallery';
import {
    EnteFile,
    EncryptedEnteFile,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from 'types/file';
import { decodeLivePhoto } from 'services/livePhotoService';
import { getFileType } from 'services/typeDetectionService';
import { logError } from '@ente/shared/sentry';
import {
    TYPE_HEIC,
    TYPE_HEIF,
    FILE_TYPE,
    SUPPORTED_RAW_FORMATS,
    RAW_FORMATS,
} from 'constants/file';
import CastDownloadManager from 'services/castDownloadManager';
import heicConversionService from 'services/heicConversionService';
import * as ffmpegService from 'services/ffmpeg/ffmpegService';
import { isArchivedFile } from 'utils/magicMetadata';

import { CustomError } from '@ente/shared/error';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import isElectron from 'is-electron';
import { isPlaybackPossible } from 'utils/photoFrame';
import { FileTypeInfo } from 'types/upload';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import { User } from '@ente/shared/user/types';
import { addLogLine, addLocalLog } from '@ente/shared/logging';
import { convertBytesToHumanReadable } from '@ente/shared/utils/size';

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

export async function getRenderableFileURL(file: EnteFile, fileBlob: Blob) {
    switch (file.metadata.fileType) {
        case FILE_TYPE.IMAGE: {
            const convertedBlob = await getRenderableImage(
                file.metadata.title,
                fileBlob
            );
            const { originalURL, convertedURL } = getFileObjectURLs(
                fileBlob,
                convertedBlob
            );
            return {
                converted: [convertedURL],
                original: [originalURL],
            };
        }
        case FILE_TYPE.LIVE_PHOTO: {
            return await getRenderableLivePhotoURL(file, fileBlob);
        }
        case FILE_TYPE.VIDEO: {
            const convertedBlob = await getPlayableVideo(
                file.metadata.title,
                fileBlob
            );
            const { originalURL, convertedURL } = getFileObjectURLs(
                fileBlob,
                convertedBlob
            );
            return {
                converted: [convertedURL],
                original: [originalURL],
            };
        }
        default: {
            const previewURL = await createTypedObjectURL(
                fileBlob,
                file.metadata.title
            );
            return {
                converted: [previewURL],
                original: [previewURL],
            };
        }
    }
}

async function getRenderableLivePhotoURL(
    file: EnteFile,
    fileBlob: Blob
): Promise<{ original: string[]; converted: string[] }> {
    const livePhoto = await decodeLivePhoto(file, fileBlob);
    const imageBlob = new Blob([livePhoto.image]);
    const videoBlob = new Blob([livePhoto.video]);
    const convertedImageBlob = await getRenderableImage(
        livePhoto.imageNameTitle,
        imageBlob
    );
    const convertedVideoBlob = await getPlayableVideo(
        livePhoto.videoNameTitle,
        videoBlob,
        true
    );
    const { originalURL: originalImageURL, convertedURL: convertedImageURL } =
        getFileObjectURLs(imageBlob, convertedImageBlob);

    const { originalURL: originalVideoURL, convertedURL: convertedVideoURL } =
        getFileObjectURLs(videoBlob, convertedVideoBlob);
    return {
        converted: [convertedImageURL, convertedVideoURL],
        original: [originalImageURL, originalVideoURL],
    };
}

export async function getPlayableVideo(
    videoNameTitle: string,
    videoBlob: Blob,
    forceConvert = false
) {
    try {
        const isPlayable = await isPlaybackPossible(
            URL.createObjectURL(videoBlob)
        );
        if (isPlayable && !forceConvert) {
            return videoBlob;
        } else {
            if (!forceConvert && !isElectron()) {
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
                // convertedImageBlob = await imageProcessor.convertToJPEG(
                //     imageBlob,
                //     fileName
                // );
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

export function isRawFileFromFileName(fileName: string) {
    for (const rawFormat of RAW_FORMATS) {
        if (fileName.toLowerCase().endsWith(rawFormat)) {
            return true;
        }
    }
    return false;
}

export function isSupportedRawFormat(exactType: string) {
    return SUPPORTED_RAW_FORMATS.includes(exactType.toLowerCase());
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

export async function getFileFromURL(fileURL: string) {
    const fileBlob = await (await fetch(fileURL)).blob();
    const fileFile = new File([fileBlob], 'temp');
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

export function getPersonalFiles(files: EnteFile[], user: User) {
    if (!user?.id) {
        throw Error('user missing');
    }
    return files.filter((file) => file.ownerID === user.id);
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

export const getPreviewableImage = async (
    file: EnteFile,
    castToken: string
): Promise<Blob> => {
    try {
        let fileBlob: Blob;
        const fileURL = await CastDownloadManager.getCachedOriginalFile(
            file
        )[0];
        if (!fileURL) {
            fileBlob = await new Response(
                await CastDownloadManager.downloadFile(castToken, file)
            ).blob();
        } else {
            fileBlob = await (await fetch(fileURL)).blob();
        }
        if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
            const livePhoto = await decodeLivePhoto(file, fileBlob);
            fileBlob = new Blob([livePhoto.image]);
        }
        const convertedBlob = await getRenderableImage(
            file.metadata.title,
            fileBlob
        );
        fileBlob = convertedBlob;
        const fileType = await getFileType(
            new File([fileBlob], file.metadata.title)
        );

        fileBlob = new Blob([fileBlob], { type: fileType.mimeType });
        return fileBlob;
    } catch (e) {
        logError(e, 'failed to download file');
    }
};

const getFileObjectURLs = (originalBlob: Blob, convertedBlob: Blob) => {
    const originalURL = URL.createObjectURL(originalBlob);
    const convertedURL = convertedBlob
        ? convertedBlob === originalBlob
            ? originalURL
            : URL.createObjectURL(convertedBlob)
        : null;
    return { originalURL, convertedURL };
};
