import { FILE_TYPE } from "@/media/file";
import { decodeLivePhoto } from "@/media/live-photo";
import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { RAW_FORMATS } from "constants/upload";
import CastDownloadManager from "services/castDownloadManager";
import { getFileType } from "services/typeDetectionService";
import {
    EncryptedEnteFile,
    EnteFile,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from "types/file";

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

export function generateStreamFromArrayBuffer(data: Uint8Array) {
    return new ReadableStream({
        async start(controller: ReadableStreamDefaultController) {
            controller.enqueue(data);
            controller.close();
        },
    });
}

export function isRawFileFromFileName(fileName: string) {
    for (const rawFormat of RAW_FORMATS) {
        if (fileName.toLowerCase().endsWith(rawFormat)) {
            return true;
        }
    }
    return false;
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

export const getPreviewableImage = async (
    file: EnteFile,
    castToken: string,
): Promise<Blob> => {
    try {
        let fileBlob = await new Response(
            await CastDownloadManager.downloadFile(castToken, file),
        ).blob();
        if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
            const { imageData } = await decodeLivePhoto(
                file.metadata.title,
                fileBlob,
            );
            fileBlob = new Blob([imageData]);
        }
        const fileType = await getFileType(
            new File([fileBlob], file.metadata.title),
        );
        fileBlob = new Blob([fileBlob], { type: fileType.mimeType });
        return fileBlob;
    } catch (e) {
        log.error("failed to download file", e);
    }
};
