import { MULTIPART_PART_SIZE, FILE_READER_CHUNK_SIZE } from 'constants/upload';
import {
    FileTypeInfo,
    FileInMemory,
    Metadata,
    B64EncryptionResult,
    EncryptedFile,
    EncryptionResult,
    FileWithMetadata,
    ParsedMetadataJSONMap,
    DataStream,
    ElectronFile,
} from 'types/upload';
import { splitFilenameAndExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { getFileNameSize, addLogLine } from 'utils/logging';
import { encryptFiledata } from './encryptionService';
import { extractMetadata, getMetadataJSONMapKey } from './metadataService';
import {
    getFileStream,
    getElectronFileStream,
    getUint8ArrayView,
} from '../readerService';
import { generateThumbnail } from './thumbnailService';
import uploadService from './uploadService';
import { CustomError } from 'utils/error';

const EDITED_FILE_SUFFIX = '-edited';

export function getFileSize(file: File | ElectronFile) {
    return file.size;
}

export function getFilename(file: File | ElectronFile) {
    return file.name;
}

export async function readFile(
    fileTypeInfo: FileTypeInfo,
    rawFile: File | ElectronFile
): Promise<FileInMemory> {
    if (uploadService.isUploadPausing()) {
        throw Error(CustomError.UPLOAD_PAUSED);
    }
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        rawFile,
        fileTypeInfo
    );
    addLogLine(`reading file data ${getFileNameSize(rawFile)} `);
    let filedata: Uint8Array | DataStream;
    if (!(rawFile instanceof File)) {
        if (rawFile.size > MULTIPART_PART_SIZE) {
            filedata = await getElectronFileStream(
                rawFile,
                FILE_READER_CHUNK_SIZE
            );
        } else {
            filedata = await getUint8ArrayView(rawFile);
        }
    } else if (rawFile.size > MULTIPART_PART_SIZE) {
        filedata = getFileStream(rawFile, FILE_READER_CHUNK_SIZE);
    } else {
        filedata = await getUint8ArrayView(rawFile);
    }

    addLogLine(`read file data successfully ${getFileNameSize(rawFile)} `);

    return {
        filedata,
        thumbnail,
        hasStaticThumbnail,
    };
}

export async function extractFileMetadata(
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    rawFile: File | ElectronFile,
    collectionID: number,
    fileTypeInfo: FileTypeInfo
) {
    const originalName = getFileOriginalName(rawFile);
    const googleMetadata =
        parsedMetadataJSONMap.get(
            getMetadataJSONMapKey(collectionID, originalName)
        ) ?? {};
    const extractedMetadata: Metadata = await extractMetadata(
        rawFile,
        fileTypeInfo
    );

    for (const [key, value] of Object.entries(googleMetadata)) {
        if (!value) {
            continue;
        }
        extractedMetadata[key] = value;
    }
    return extractedMetadata;
}

export async function encryptFile(
    worker: any,
    file: FileWithMetadata,
    encryptionKey: string
): Promise<EncryptedFile> {
    try {
        if (uploadService.isUploadPausing()) {
            throw Error(CustomError.UPLOAD_PAUSED);
        }
        const { key: fileKey, file: encryptedFiledata } = await encryptFiledata(
            worker,
            file.filedata
        );

        const { file: encryptedThumbnail }: EncryptionResult =
            await worker.encryptThumbnail(file.thumbnail, fileKey);
        const { file: encryptedMetadata }: EncryptionResult =
            await worker.encryptMetadata(file.metadata, fileKey);

        const encryptedKey: B64EncryptionResult = await worker.encryptToB64(
            fileKey,
            encryptionKey
        );

        const result: EncryptedFile = {
            file: {
                file: encryptedFiledata,
                thumbnail: encryptedThumbnail,
                metadata: encryptedMetadata,
                localID: file.localID,
            },
            fileKey: encryptedKey,
        };
        return result;
    } catch (e) {
        logError(e, 'Error encrypting files');
        throw e;
    }
}

/*
    Get the original file name for edited file to associate it to original file's metadataJSON file 
    as edited file doesn't have their own metadata file
*/
function getFileOriginalName(file: File | ElectronFile) {
    let originalName: string = null;
    const [nameWithoutExtension, extension] = splitFilenameAndExtension(
        file.name
    );

    const isEditedFile = nameWithoutExtension.endsWith(EDITED_FILE_SUFFIX);
    if (isEditedFile) {
        originalName = nameWithoutExtension.slice(
            0,
            -1 * EDITED_FILE_SUFFIX.length
        );
    } else {
        originalName = nameWithoutExtension;
    }
    if (extension) {
        originalName += '.' + extension;
    }
    return originalName;
}
