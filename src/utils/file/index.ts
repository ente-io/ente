import { SelectedState } from 'pages/gallery';
import { Collection } from 'services/collectionService';
import {
    File,
    fileAttribute,
    FILE_TYPE,
    MagicMetadataProps,
    NEW_MAGIC_METADATA,
    PublicMagicMetadataProps,
    VISIBILITY_STATE,
} from 'services/fileService';
import { decodeMotionPhoto } from 'services/motionPhotoService';
import { getMimeTypeFromBlob } from 'services/upload/readFileService';
import DownloadManger from 'services/downloadManager';
import { logError } from 'utils/sentry';
import { User } from 'services/userService';
import CryptoWorker from 'utils/crypto';
import { getData, LS_KEYS } from 'utils/storage/localStorage';

export const TYPE_HEIC = 'heic';
export const TYPE_HEIF = 'heif';
const UNSUPPORTED_FORMATS = ['flv', 'mkv', '3gp', 'avi', 'wmv'];

export function downloadAsFile(filename: string, content: string) {
    const file = new Blob([content], {
        type: 'text/plain',
    });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(file);
    a.download = filename;

    a.style.display = 'none';
    document.body.appendChild(a);

    a.click();

    a.remove();
}

export async function downloadFile(file) {
    const a = document.createElement('a');
    a.style.display = 'none';
    a.href = await DownloadManger.getFile(file);
    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        a.download = fileNameWithoutExtension(file.metadata.title) + '.zip';
    } else {
        a.download = file.metadata.title;
    }
    document.body.appendChild(a);
    a.click();
    a.remove();
}

export function fileIsHEIC(mimeType: string) {
    return (
        mimeType.toLowerCase().endsWith(TYPE_HEIC) ||
        mimeType.toLowerCase().endsWith(TYPE_HEIF)
    );
}

export function sortFilesIntoCollections(files: File[]) {
    const collectionWiseFiles = new Map<number, File[]>();
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
    return filesIDs;
}
export function getSelectedFiles(
    selected: SelectedState,
    files: File[]
): File[] {
    const filesIDs = new Set(getSelectedFileIds(selected));
    const selectedFiles: File[] = [];
    const foundFiles = new Set<number>();
    for (const file of files) {
        if (filesIDs.has(file.id) && !foundFiles.has(file.id)) {
            selectedFiles.push(file);
            foundFiles.add(file.id);
        }
    }
    return selectedFiles;
}

export function checkFileFormatSupport(name: string) {
    for (const format of UNSUPPORTED_FORMATS) {
        if (name.toLowerCase().endsWith(format)) {
            throw Error('unsupported format');
        }
    }
}

export function formatDate(date: number | Date) {
    const dateTimeFormat = new Intl.DateTimeFormat('en-IN', {
        weekday: 'short',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    });
    return dateTimeFormat.format(date);
}

export function formatDateTime(date: number | Date) {
    const dateTimeFormat = new Intl.DateTimeFormat('en-IN', {
        weekday: 'short',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    });
    const timeFormat = new Intl.DateTimeFormat('en-IN', {
        timeStyle: 'medium',
    });
    return `${dateTimeFormat.format(date)} ${timeFormat.format(date)}`;
}

export function formatDateRelative(date: number) {
    const units = {
        year: 24 * 60 * 60 * 1000 * 365,
        month: (24 * 60 * 60 * 1000 * 365) / 12,
        day: 24 * 60 * 60 * 1000,
        hour: 60 * 60 * 1000,
        minute: 60 * 1000,
        second: 1000,
    };
    const relativeDateFormat = new Intl.RelativeTimeFormat('en-IN', {
        localeMatcher: 'best fit',
        numeric: 'always',
        style: 'long',
    });
    const elapsed = date - Date.now();

    // "Math.abs" accounts for both "past" & "future" scenarios
    for (const u in units)
        if (Math.abs(elapsed) > units[u] || u === 'second')
            return relativeDateFormat.format(
                Math.round(elapsed / units[u]),
                u as Intl.RelativeTimeFormatUnit
            );
}

export function sortFiles(files: File[]) {
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

export async function decryptFile(file: File, collection: Collection) {
    try {
        const worker = await new CryptoWorker();
        file.key = await worker.decryptB64(
            file.encryptedKey,
            file.keyDecryptionNonce,
            collection.key
        );
        const encryptedMetadata = file.metadata as unknown as fileAttribute;
        file.metadata = await worker.decryptMetadata(
            encryptedMetadata.encryptedData,
            encryptedMetadata.decryptionHeader,
            file.key
        );
        if (file.magicMetadata?.data) {
            file.magicMetadata.data = await worker.decryptMetadata(
                file.magicMetadata.data,
                file.magicMetadata.header,
                file.key
            );
        }
        if (file.pubMagicMetadata?.data) {
            file.pubMagicMetadata.data = await worker.decryptMetadata(
                file.pubMagicMetadata.data,
                file.pubMagicMetadata.header,
                file.key
            );
        }
        return file;
    } catch (e) {
        logError(e, 'file decryption failed');
        throw e;
    }
}

export function removeUnnecessaryFileProps(files: File[]): File[] {
    const stripedFiles = files.map((file) => {
        delete file.src;
        delete file.msrc;
        delete file.file.objectKey;
        delete file.thumbnail.objectKey;
        delete file.h;
        delete file.html;
        delete file.w;

        return file;
    });
    return stripedFiles;
}

export function fileNameWithoutExtension(filename) {
    const lastDotPosition = filename.lastIndexOf('.');
    if (lastDotPosition === -1) return filename;
    else return filename.substr(0, lastDotPosition);
}

export function fileExtensionWithDot(filename) {
    const lastDotPosition = filename.lastIndexOf('.');
    if (lastDotPosition === -1) return '';
    else return filename.substr(lastDotPosition);
}

export function generateStreamFromArrayBuffer(data: Uint8Array) {
    return new ReadableStream({
        async start(controller: ReadableStreamDefaultController) {
            controller.enqueue(data);
            controller.close();
        },
    });
}

export async function convertForPreview(file: File, fileBlob: Blob) {
    if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
        const originalName = fileNameWithoutExtension(file.metadata.title);
        const motionPhoto = await decodeMotionPhoto(fileBlob, originalName);
        fileBlob = new Blob([motionPhoto.image]);
    }

    const typeFromExtension = file.metadata.title.split('.')[-1];
    const worker = await new CryptoWorker();

    const mimeType =
        (await getMimeTypeFromBlob(worker, fileBlob)) ?? typeFromExtension;
    if (fileIsHEIC(mimeType)) {
        fileBlob = await worker.convertHEIC2JPEG(fileBlob);
    }
    return fileBlob;
}

export function fileIsArchived(file: File) {
    if (
        !file ||
        !file.magicMetadata ||
        !file.magicMetadata.data ||
        typeof file.magicMetadata.data === 'string' ||
        typeof file.magicMetadata.data.visibility === 'undefined'
    ) {
        return false;
    }
    return file.magicMetadata.data.visibility === VISIBILITY_STATE.ARCHIVED;
}

export async function updateMagicMetadataProps(
    file: File,
    magicMetadataUpdates: MagicMetadataProps
) {
    const worker = await new CryptoWorker();

    if (!file.magicMetadata) {
        file.magicMetadata = NEW_MAGIC_METADATA;
    }
    if (typeof file.magicMetadata.data === 'string') {
        file.magicMetadata.data = (await worker.decryptMetadata(
            file.magicMetadata.data,
            file.magicMetadata.header,
            file.key
        )) as MagicMetadataProps;
    }
    if (magicMetadataUpdates) {
        // copies the existing magic metadata properties of the files and updates the visibility value
        // The expected behaviour while updating magic metadata is to let the existing property as it is and update/add the property you want
        const magicMetadataProps: MagicMetadataProps = {
            ...file.magicMetadata.data,
            ...magicMetadataUpdates,
        };

        return {
            ...file,
            magicMetadata: {
                ...file.magicMetadata,
                data: magicMetadataProps,
                count: Object.keys(file.magicMetadata.data).length,
            },
        };
    } else {
        return file;
    }
}
export async function updatePublicMagicMetadataProps(
    file: File,
    publicMetadataUpdates: PublicMagicMetadataProps
) {
    const worker = await new CryptoWorker();

    if (!file.pubMagicMetadata) {
        file.pubMagicMetadata = NEW_MAGIC_METADATA;
    }
    if (typeof file.pubMagicMetadata.data === 'string') {
        file.pubMagicMetadata.data = (await worker.decryptMetadata(
            file.pubMagicMetadata.data,
            file.pubMagicMetadata.header,
            file.key
        )) as PublicMagicMetadataProps;
    }

    if (publicMetadataUpdates) {
        const publicMetadataProps = {
            ...file.pubMagicMetadata.data,
            ...publicMetadataUpdates,
        };
        return {
            ...file,
            pubMagicMetadata: {
                ...file.pubMagicMetadata,
                data: publicMetadataProps,
                count: Object.keys(file.pubMagicMetadata.data).length,
            },
        };
    } else {
        return file;
    }
}

export async function changeFilesVisibility(
    files: File[],
    selected: SelectedState,
    visibility: VISIBILITY_STATE
) {
    const selectedFiles = getSelectedFiles(selected, files);
    const updatedFiles: File[] = [];
    for (const file of selectedFiles) {
        const updatedMagicMetadataProps: MagicMetadataProps = {
            visibility,
        };

        updatedFiles.push(
            await updateMagicMetadataProps(file, updatedMagicMetadataProps)
        );
    }
    return updatedFiles;
}

export async function changeFileCreationTime(file: File, editedTime: number) {
    const updatedPublicMagicMetadataProps: PublicMagicMetadataProps = {
        editedTime,
    };

    return await updatePublicMagicMetadataProps(
        file,
        updatedPublicMagicMetadataProps
    );
}

export function isSharedFile(file: File) {
    const user: User = getData(LS_KEYS.USER);

    if (!user?.id || !file?.ownerID) {
        return false;
    }
    return file.ownerID !== user.id;
}

export function mergeMetadata(files: File[]): File[] {
    return files.map((file) => ({
        ...file,
        metadata: {
            ...file.metadata,
            ...(file.pubMagicMetadata?.data
                ? {
                      ...(file.pubMagicMetadata?.data.editedTime && {
                          creationTime: file.pubMagicMetadata.data.editedTime,
                      }),
                  }
                : {}),
            ...(file.magicMetadata?.data ? file.magicMetadata.data : {}),
        },
    }));
}

export function updateExistingFilePubMetadata(
    existingFile: File,
    updatedFile: File
) {
    existingFile.pubMagicMetadata = updatedFile.pubMagicMetadata;
    existingFile.metadata = mergeMetadata([existingFile])[0].metadata;
}
