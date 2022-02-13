import { Collection } from 'types/collection';
import {
    FileTypeInfo,
    FileInMemory,
    Metadata,
    B64EncryptionResult,
    EncryptedFile,
    EncryptionResult,
    FileWithMetadata,
} from 'types/upload';
import { logError } from 'utils/sentry';
import { encryptFiledata } from './encryptionService';
import { getMetadataMapKey, extractMetadata } from './metadataService';
import { getFileData, getFileOriginalName } from './readFileService';
import { generateThumbnail } from './thumbnailService';

export function getFileSize(file: File) {
    return file.size;
}

export async function readFile(
    worker: any,
    reader: FileReader,
    fileTypeInfo: FileTypeInfo,
    rawFile: File
): Promise<FileInMemory> {
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        worker,
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

export async function getFileMetadata(
    rawFile: File,
    collection: Collection,
    fileTypeInfo: FileTypeInfo
) {
    const originalName = getFileOriginalName(rawFile);
    const googleMetadata =
        this.metadataMap.get(getMetadataMapKey(collection.id, originalName)) ??
        {};
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
                filename: file.metadata.title,
            },
            fileKey: encryptedKey,
        };
        return result;
    } catch (e) {
        logError(e, 'Error encrypting files');
        throw e;
    }
}
