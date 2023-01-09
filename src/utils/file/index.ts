import { SelectedState } from 'types/gallery';
import { EnteFile, EncryptedEnteFile } from 'types/file';
import { decodeMotionPhoto } from 'services/motionPhotoService';
import { getFileType } from 'services/typeDetectionService';
import DownloadManager from 'services/downloadManager';
import { logError } from 'utils/sentry';
import { User } from 'types/user';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { updateFileCreationDateInEXIF } from 'services/upload/exifService';
import {
    TYPE_JPEG,
    TYPE_JPG,
    TYPE_HEIC,
    TYPE_HEIF,
    FILE_TYPE,
} from 'constants/file';
import PublicCollectionDownloadManager from 'services/publicCollectionDownloadManager';
import heicConversionService from 'services/heicConversionService';
import * as ffmpegService from 'services/ffmpeg/ffmpegService';
import {
    FileMagicMetadata,
    FileMagicMetadataProps,
    FilePublicMagicMetadata,
    FilePublicMagicMetadataProps,
    NEW_FILE_MAGIC_METADATA,
    VISIBILITY_STATE,
} from 'types/magicMetadata';
import { IsArchived, updateMagicMetadataProps } from 'utils/magicMetadata';

import { addLogLine } from 'utils/logging';
import { CustomError } from 'utils/error';
import { convertBytesToHumanReadable } from './size';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';

const WAIT_TIME_IMAGE_CONVERSION = 30 * 1000;

export function downloadAsFile(filename: string, content: string) {
    const file = new Blob([content], {
        type: 'text/plain',
    });
    const fileURL = URL.createObjectURL(file);
    downloadUsingAnchor(fileURL, filename);
}

export async function downloadFile(
    file: EnteFile,
    accessedThroughSharedURL: boolean,
    token?: string,
    passwordToken?: string
) {
    let fileBlob: Blob;
    const fileReader = new FileReader();
    if (accessedThroughSharedURL) {
        const fileURL =
            await PublicCollectionDownloadManager.getCachedOriginalFile(
                file
            )[0];
        if (!fileURL) {
            fileBlob = await new Response(
                await PublicCollectionDownloadManager.downloadFile(
                    token,
                    passwordToken,
                    file
                )
            ).blob();
        } else {
            fileBlob = await (await fetch(fileURL)).blob();
        }
    } else {
        const fileURL = await DownloadManager.getCachedOriginalFile(file)[0];
        if (!fileURL) {
            fileBlob = await new Response(
                await DownloadManager.downloadFile(file)
            ).blob();
        } else {
            fileBlob = await (await fetch(fileURL)).blob();
        }
    }

    const fileType = await getFileType(
        new File([fileBlob], file.metadata.title)
    );
    if (
        file.pubMagicMetadata?.data.editedTime &&
        (fileType.exactType === TYPE_JPEG || fileType.exactType === TYPE_JPG)
    ) {
        fileBlob = await updateFileCreationDateInEXIF(
            fileReader,
            fileBlob,
            new Date(file.pubMagicMetadata.data.editedTime / 1000)
        );
    }
    let tempImageURL: string;
    let tempVideoURL: string;
    let tempURL: string;

    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        const originalName = fileNameWithoutExtension(file.metadata.title);
        const motionPhoto = await decodeMotionPhoto(fileBlob, originalName);
        const image = new File([motionPhoto.image], motionPhoto.imageNameTitle);
        const imageType = await getFileType(image);
        tempImageURL = URL.createObjectURL(
            new Blob([motionPhoto.image], { type: imageType.mimeType })
        );
        const video = new File([motionPhoto.video], motionPhoto.videoNameTitle);
        const videoType = await getFileType(video);
        tempVideoURL = URL.createObjectURL(
            new Blob([motionPhoto.video], { type: videoType.mimeType })
        );
        downloadUsingAnchor(tempImageURL, motionPhoto.imageNameTitle);
        downloadUsingAnchor(tempVideoURL, motionPhoto.videoNameTitle);
    } else {
        fileBlob = new Blob([fileBlob], { type: fileType.mimeType });
        tempURL = URL.createObjectURL(fileBlob);
        downloadUsingAnchor(tempURL, file.metadata.title);
    }
}

function downloadUsingAnchor(link: string, name: string) {
    const a = document.createElement('a');
    a.style.display = 'none';
    a.href = link;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    URL.revokeObjectURL(link);
    a.remove();
}

export function groupFilesBasedOnCollectionID(files: EnteFile[]) {
    const collectionWiseFiles = new Map<number, EnteFile[]>();
    for (const file of files) {
        if (!collectionWiseFiles.has(file.collectionID)) {
            collectionWiseFiles.set(file.collectionID, []);
        }
        if (!file.isTrashed) {
            collectionWiseFiles.get(file.collectionID).push(file);
        }
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
    return filesIDs;
}
export function getSelectedFiles(
    selected: SelectedState,
    files: EnteFile[]
): EnteFile[] {
    const filesIDs = new Set(getSelectedFileIds(selected));
    const selectedFiles: EnteFile[] = [];
    const foundFiles = new Set<number>();
    for (const file of files) {
        if (filesIDs.has(file.id) && !foundFiles.has(file.id)) {
            selectedFiles.push(file);
            foundFiles.add(file.id);
        }
    }
    return selectedFiles;
}

export function sortFiles(files: EnteFile[]) {
    // sort according to modification time first
    files = files.sort((a, b) => {
        if (!b.metadata?.modificationTime) {
            return -1;
        }
        if (!a.metadata?.modificationTime) {
            return 1;
        } else {
            return b.metadata.modificationTime - a.metadata.modificationTime;
        }
    });

    // then sort according to creation time, maintaining ordering according to modification time for files with creation time
    files = files
        .map((file, index) => ({ index, file }))
        .sort((a, b) => {
            let diff =
                b.file.metadata.creationTime - a.file.metadata.creationTime;
            if (diff === 0) {
                diff = a.index - b.index;
            }
            return diff;
        })
        .map((file) => file.file);
    return files;
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

export const preservePhotoswipeProps =
    (newFiles: EnteFile[]) =>
    (currentFiles: EnteFile[]): EnteFile[] => {
        const currentFilesMap = Object.fromEntries(
            currentFiles.map((file) => [file.id, file])
        );
        const fileWithPreservedProperty = newFiles.map((file) => {
            const currentFile = currentFilesMap[file.id];
            return { ...currentFile, ...file };
        });
        return fileWithPreservedProperty;
    };

export function fileNameWithoutExtension(filename: string) {
    const lastDotPosition = filename.lastIndexOf('.');
    if (lastDotPosition === -1) return filename;
    else return filename.slice(0, lastDotPosition);
}

export function fileExtensionWithDot(filename: string) {
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
            return {
                converted: [URL.createObjectURL(convertedBlob)],
                original: [URL.createObjectURL(fileBlob)],
            };
        }
        case FILE_TYPE.LIVE_PHOTO: {
            const livePhoto = await getRenderableLivePhoto(file, fileBlob);
            return {
                converted: livePhoto.map((asset) => URL.createObjectURL(asset)),
                original: [URL.createObjectURL(fileBlob)],
            };
        }
        default: {
            const previewURL = URL.createObjectURL(fileBlob);
            return {
                converted: [previewURL],
                original: [previewURL],
            };
        }
    }
}

async function getRenderableLivePhoto(
    file: EnteFile,
    fileBlob: Blob
): Promise<Blob[]> {
    const originalName = fileNameWithoutExtension(file.metadata.title);
    const motionPhoto = await decodeMotionPhoto(fileBlob, originalName);
    const imageBlob = new Blob([motionPhoto.image]);
    return await Promise.all([
        getRenderableImage(motionPhoto.imageNameTitle, imageBlob),
        getPlayableVideo(motionPhoto.videoNameTitle, motionPhoto.video),
    ]);
}

async function getPlayableVideo(videoNameTitle: string, video: Uint8Array) {
    const mp4ConvertedVideo = await ffmpegService.convertToMP4(
        new File([video], videoNameTitle)
    );
    return new Blob([await mp4ConvertedVideo.arrayBuffer()]);
}

async function getRenderableImage(fileName: string, imageBlob: Blob) {
    if (await isFileHEIC(imageBlob, fileName)) {
        addLogLine(
            `HEICConverter called for ${fileName}-${convertBytesToHumanReadable(
                imageBlob.size
            )}`
        );
        const convertedImageBlob = await heicConversionService.convert(
            imageBlob
        );

        addLogLine(`${fileName} successfully converted`);
        return convertedImageBlob;
    } else {
        return imageBlob;
    }
}

export async function isFileHEIC(fileBlob: Blob, fileName: string) {
    const tempFile = new File([fileBlob], fileName);
    const { exactType } = await getFileType(tempFile);
    return isExactTypeHEIC(exactType);
}

export function isExactTypeHEIC(exactType: string) {
    return (
        exactType.toLowerCase().endsWith(TYPE_HEIC) ||
        exactType.toLowerCase().endsWith(TYPE_HEIF)
    );
}

export async function changeFilesVisibility(
    files: EnteFile[],
    selected: SelectedState,
    visibility: VISIBILITY_STATE
) {
    const selectedFiles = getSelectedFiles(selected, files);
    const updatedFiles: EnteFile[] = [];
    for (const file of selectedFiles) {
        const updatedMagicMetadataProps: FileMagicMetadataProps = {
            visibility,
        };

        updatedFiles.push({
            ...file,
            magicMetadata: await updateMagicMetadataProps(
                file.magicMetadata ?? NEW_FILE_MAGIC_METADATA,
                file.key,
                updatedMagicMetadataProps
            ),
        });
    }
    return updatedFiles;
}

export async function changeFileCreationTime(
    file: EnteFile,
    editedTime: number
) {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        editedTime,
    };
    file.pubMagicMetadata = await updateMagicMetadataProps(
        file.pubMagicMetadata ?? NEW_FILE_MAGIC_METADATA,
        file.key,
        updatedPublicMagicMetadataProps
    );
    return file;
}

export async function changeFileName(file: EnteFile, editedName: string) {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        editedName,
    };

    file.pubMagicMetadata = await updateMagicMetadataProps(
        file.pubMagicMetadata ?? NEW_FILE_MAGIC_METADATA,
        file.key,
        updatedPublicMagicMetadataProps
    );
    return file;
}

export async function changeCaption(file: EnteFile, caption: string) {
    const updatedPublicMagicMetadataProps: FilePublicMagicMetadataProps = {
        caption,
    };

    file.pubMagicMetadata = await updateMagicMetadataProps(
        file.pubMagicMetadata ?? NEW_FILE_MAGIC_METADATA,
        file.key,
        updatedPublicMagicMetadataProps
    );
    return file;
}

export function isSharedFile(user: User, file: EnteFile) {
    if (!user?.id || !file?.ownerID) {
        return false;
    }
    return file.ownerID !== user.id;
}

export function mergeMetadata(files: EnteFile[]): EnteFile[] {
    return files.map((file) => ({
        ...file,
        metadata: {
            ...file.metadata,
            ...(file.pubMagicMetadata?.data
                ? {
                      ...(file.pubMagicMetadata?.data.editedTime && {
                          creationTime: file.pubMagicMetadata.data.editedTime,
                      }),
                      ...(file.pubMagicMetadata?.data.editedName && {
                          title: file.pubMagicMetadata.data.editedName,
                      }),
                  }
                : {}),
            ...(file.magicMetadata?.data ? file.magicMetadata.data : {}),
        },
    }));
}

export function updateExistingFilePubMetadata(
    existingFile: EnteFile,
    updatedFile: EnteFile
) {
    existingFile.pubMagicMetadata = updatedFile.pubMagicMetadata;
    existingFile.metadata = mergeMetadata([existingFile])[0].metadata;
}

export async function getFileFromURL(fileURL: string) {
    const fileBlob = await (await fetch(fileURL)).blob();
    const fileFile = new File([fileBlob], 'temp');
    return fileFile;
}

export function getUniqueFiles(files: EnteFile[]) {
    const idSet = new Set<number>();
    return files.filter((file) => {
        if (!idSet.has(file.id)) {
            idSet.add(file.id);
            return true;
        } else {
            return false;
        }
    });
}
export function getNonTrashedFiles(files: EnteFile[]) {
    return files.filter(
        (file) => typeof file.isTrashed === 'undefined' || !file.isTrashed
    );
}

export async function downloadFiles(files: EnteFile[]) {
    for (const file of files) {
        try {
            await downloadFile(file, false);
        } catch (e) {
            logError(e, 'download fail for file');
        }
    }
}

export async function needsConversionForPreview(
    file: EnteFile,
    fileBlob: Blob
) {
    const isHEIC = await isFileHEIC(fileBlob, file.metadata.title);
    return (
        file.metadata.fileType === FILE_TYPE.LIVE_PHOTO ||
        (file.metadata.fileType === FILE_TYPE.IMAGE && isHEIC)
    );
}

export const isLivePhoto = (file: EnteFile) =>
    file.metadata.fileType === FILE_TYPE.LIVE_PHOTO;

export const isImageOrVideo = (fileType: FILE_TYPE) =>
    [FILE_TYPE.IMAGE, FILE_TYPE.VIDEO].includes(fileType);

export const getArchivedFiles = (files: EnteFile[]) => {
    return files.filter(IsArchived).map((file) => file.id);
};

export const createTypedObjectURL = async (blob: Blob, fileName: string) => {
    const type = await getFileType(new File([blob], fileName));
    return URL.createObjectURL(new Blob([blob], { type: type.mimeType }));
};

export const getUserOwnedNonTrashedFiles = (files: EnteFile[]) => {
    const user: User = getData(LS_KEYS.USER);
    if (!user?.id) {
        throw Error('user missing');
    }
    return files.filter((file) => file.isTrashed || file.ownerID === user.id);
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
