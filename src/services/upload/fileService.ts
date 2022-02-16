import {
    FileTypeInfo,
    FileInMemory,
    Metadata,
    B64EncryptionResult,
    EncryptedFile,
    EncryptionResult,
    FileWithMetadata,
    ParsedMetadataJSONMap,
} from 'types/upload';
import { logError } from 'utils/sentry';
import { encryptFiledata } from './encryptionService';
import { extractMetadata, getMetadataJSONMapKey } from './metadataService';
import { getFileData, getFileOriginalName } from './readFileService';
import { generateThumbnail } from './thumbnailService';

export function getFileSize(file: File) {
    return file.size;
}

export function getFilename(file: File) {
    return file.name;
}

export async function readFile(
    reader: FileReader,
    fileTypeInfo: FileTypeInfo,
    rawFile: File
): Promise<FileInMemory> {
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        reader,
        rawFile,
        fileTypeInfo
    );

    const filedata = await getFileData(reader, rawFile);

    return {
        filedata,
        thumbnail,
        hasStaticThumbnail,
    };
}

export async function extractFileMetadata(
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    rawFile: File,
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
