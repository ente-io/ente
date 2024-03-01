import { addLogLine } from "@ente/shared/logging";
import { getFileNameSize } from "@ente/shared/logging/web";
import { logError } from "@ente/shared/sentry";
import { FILE_READER_CHUNK_SIZE, MULTIPART_PART_SIZE } from "constants/upload";
import {
    DataStream,
    ElectronFile,
    EncryptedFile,
    ExtractMetadataResult,
    FileInMemory,
    FileTypeInfo,
    FileWithMetadata,
    ParsedMetadataJSON,
    ParsedMetadataJSONMap,
} from "types/upload";

import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { Remote } from "comlink";
import { EncryptedMagicMetadata } from "types/magicMetadata";
import {
    getElectronFileStream,
    getFileStream,
    getUint8ArrayView,
} from "../readerService";
import { encryptFiledata } from "./encryptionService";
import {
    MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT,
    extractMetadata,
    getClippedMetadataJSONMapKeyForFile,
    getMetadataJSONMapKeyForFile,
} from "./metadataService";
import { generateThumbnail } from "./thumbnailService";

export function getFileSize(file: File | ElectronFile) {
    return file.size;
}

export function getFilename(file: File | ElectronFile) {
    return file.name;
}

export async function readFile(
    fileTypeInfo: FileTypeInfo,
    rawFile: File | ElectronFile,
): Promise<FileInMemory> {
    const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
        rawFile,
        fileTypeInfo,
    );
    addLogLine(`reading file data ${getFileNameSize(rawFile)} `);
    let filedata: Uint8Array | DataStream;
    if (!(rawFile instanceof File)) {
        if (rawFile.size > MULTIPART_PART_SIZE) {
            filedata = await getElectronFileStream(
                rawFile,
                FILE_READER_CHUNK_SIZE,
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
    worker: Remote<DedicatedCryptoWorker>,
    parsedMetadataJSONMap: ParsedMetadataJSONMap,
    collectionID: number,
    fileTypeInfo: FileTypeInfo,
    rawFile: File | ElectronFile,
): Promise<ExtractMetadataResult> {
    let key = getMetadataJSONMapKeyForFile(collectionID, rawFile.name);
    let googleMetadata: ParsedMetadataJSON = parsedMetadataJSONMap.get(key);

    if (!googleMetadata && key.length > MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT) {
        key = getClippedMetadataJSONMapKeyForFile(collectionID, rawFile.name);
        googleMetadata = parsedMetadataJSONMap.get(key);
    }

    const { metadata, publicMagicMetadata } = await extractMetadata(
        worker,
        rawFile,
        fileTypeInfo,
    );

    for (const [key, value] of Object.entries(googleMetadata ?? {})) {
        if (!value) {
            continue;
        }
        metadata[key] = value;
    }
    return { metadata, publicMagicMetadata };
}

export async function encryptFile(
    worker: Remote<DedicatedCryptoWorker>,
    file: FileWithMetadata,
    encryptionKey: string,
): Promise<EncryptedFile> {
    try {
        const { key: fileKey, file: encryptedFiledata } = await encryptFiledata(
            worker,
            file.filedata,
        );

        const { file: encryptedThumbnail } = await worker.encryptThumbnail(
            file.thumbnail,
            fileKey,
        );
        const { file: encryptedMetadata } = await worker.encryptMetadata(
            file.metadata,
            fileKey,
        );

        let encryptedPubMagicMetadata: EncryptedMagicMetadata;
        if (file.pubMagicMetadata) {
            const { file: encryptedPubMagicMetadataData } =
                await worker.encryptMetadata(
                    file.pubMagicMetadata.data,
                    fileKey,
                );
            encryptedPubMagicMetadata = {
                version: file.pubMagicMetadata.version,
                count: file.pubMagicMetadata.count,
                data: encryptedPubMagicMetadataData.encryptedData,
                header: encryptedPubMagicMetadataData.decryptionHeader,
            };
        }

        const encryptedKey = await worker.encryptToB64(fileKey, encryptionKey);

        const result: EncryptedFile = {
            file: {
                file: encryptedFiledata,
                thumbnail: encryptedThumbnail,
                metadata: encryptedMetadata,
                pubMagicMetadata: encryptedPubMagicMetadata,
                localID: file.localID,
            },
            fileKey: encryptedKey,
        };
        return result;
    } catch (e) {
        logError(e, "Error encrypting files");
        throw e;
    }
}
