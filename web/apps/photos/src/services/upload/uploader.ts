import { convertBytesToHumanReadable } from "@/next/file";
import log from "@/next/log";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError, handleUploadError } from "@ente/shared/error";
import { sleep } from "@ente/shared/utils";
import { Remote } from "comlink";
import { MAX_FILE_SIZE_SUPPORTED, UPLOAD_RESULT } from "constants/upload";
import { addToCollection } from "services/collectionService";
import { EnteFile } from "types/file";
import {
    BackupedFile,
    FileTypeInfo,
    FileWithCollection,
    FileWithMetadata,
    Logger,
    UploadFile,
} from "types/upload";
import { findMatchingExistingFiles } from "utils/upload";
import UIService from "./uiService";
import uploadCancelService from "./uploadCancelService";
import {
    default as UploadService,
    default as uploadService,
} from "./uploadService";

interface UploadResponse {
    fileUploadResult: UPLOAD_RESULT;
    uploadedFile?: EnteFile;
}

export default async function uploader(
    worker: Remote<DedicatedCryptoWorker>,
    existingFiles: EnteFile[],
    fileWithCollection: FileWithCollection,
    uploaderName: string,
): Promise<UploadResponse> {
    const { collection, localID, ...uploadAsset } = fileWithCollection;
    const fileNameSize = `${UploadService.getAssetName(
        fileWithCollection,
    )}_${convertBytesToHumanReadable(UploadService.getAssetSize(uploadAsset))}`;

    log.info(`uploader called for  ${fileNameSize}`);
    UIService.setFileProgress(localID, 0);
    await sleep(0);
    let fileTypeInfo: FileTypeInfo;
    let fileSize: number;
    try {
        fileSize = UploadService.getAssetSize(uploadAsset);
        if (fileSize >= MAX_FILE_SIZE_SUPPORTED) {
            return { fileUploadResult: UPLOAD_RESULT.TOO_LARGE };
        }
        log.info(`getting filetype for ${fileNameSize}`);
        fileTypeInfo = await UploadService.getAssetFileType(uploadAsset);
        log.info(
            `got filetype for ${fileNameSize} - ${JSON.stringify(fileTypeInfo)}`,
        );

        log.info(`extracting  metadata ${fileNameSize}`);
        const { metadata, publicMagicMetadata } =
            await UploadService.extractAssetMetadata(
                worker,
                uploadAsset,
                collection.id,
                fileTypeInfo,
            );

        const matchingExistingFiles = findMatchingExistingFiles(
            existingFiles,
            metadata,
        );
        log.debug(
            () =>
                `matchedFileList: ${matchingExistingFiles
                    .map((f) => `${f.id}-${f.metadata.title}`)
                    .join(",")}`,
        );
        if (matchingExistingFiles?.length) {
            const matchingExistingFilesCollectionIDs =
                matchingExistingFiles.map((e) => e.collectionID);
            log.debug(
                () =>
                    `matched file collectionIDs:${matchingExistingFilesCollectionIDs}
                       and collectionID:${collection.id}`,
            );
            if (matchingExistingFilesCollectionIDs.includes(collection.id)) {
                log.info(
                    `file already present in the collection , skipped upload for  ${fileNameSize}`,
                );
                const sameCollectionMatchingExistingFile =
                    matchingExistingFiles.find(
                        (f) => f.collectionID === collection.id,
                    );
                return {
                    fileUploadResult: UPLOAD_RESULT.ALREADY_UPLOADED,
                    uploadedFile: sameCollectionMatchingExistingFile,
                };
            } else {
                log.info(
                    `same file in ${matchingExistingFilesCollectionIDs.length} collection found for  ${fileNameSize} ,adding symlink`,
                );
                // any of the matching file can used to add a symlink
                const resultFile = Object.assign({}, matchingExistingFiles[0]);
                resultFile.collectionID = collection.id;
                await addToCollection(collection, [resultFile]);
                return {
                    fileUploadResult: UPLOAD_RESULT.ADDED_SYMLINK,
                    uploadedFile: resultFile,
                };
            }
        }
        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
        log.info(`reading asset ${fileNameSize}`);

        const file = await UploadService.readAsset(fileTypeInfo, uploadAsset);

        if (file.hasStaticThumbnail) {
            metadata.hasStaticThumbnail = true;
        }

        const pubMagicMetadata =
            await uploadService.constructPublicMagicMetadata({
                ...publicMagicMetadata,
                uploaderName,
            });

        const fileWithMetadata: FileWithMetadata = {
            localID,
            filedata: file.filedata,
            thumbnail: file.thumbnail,
            metadata,
            pubMagicMetadata,
        };

        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
        log.info(`encryptAsset ${fileNameSize}`);
        const encryptedFile = await UploadService.encryptAsset(
            worker,
            fileWithMetadata,
            collection.key,
        );

        if (uploadCancelService.isUploadCancelationRequested()) {
            throw Error(CustomError.UPLOAD_CANCELLED);
        }
        log.info(`uploadToBucket ${fileNameSize}`);
        const logger: Logger = (message: string) => {
            log.info(message, `fileNameSize: ${fileNameSize}`);
        };
        const backupedFile: BackupedFile = await UploadService.uploadToBucket(
            logger,
            encryptedFile.file,
        );

        const uploadFile: UploadFile = UploadService.getUploadFile(
            collection,
            backupedFile,
            encryptedFile.fileKey,
        );
        log.info(`uploading file to server ${fileNameSize}`);

        const uploadedFile = await UploadService.uploadFile(uploadFile);

        log.info(`${fileNameSize} successfully uploaded`);

        return {
            fileUploadResult: metadata.hasStaticThumbnail
                ? UPLOAD_RESULT.UPLOADED_WITH_STATIC_THUMBNAIL
                : UPLOAD_RESULT.UPLOADED,
            uploadedFile: uploadedFile,
        };
    } catch (e) {
        log.info(`upload failed for  ${fileNameSize} ,error: ${e.message}`);
        if (
            e.message !== CustomError.UPLOAD_CANCELLED &&
            e.message !== CustomError.UNSUPPORTED_FILE_FORMAT
        ) {
            log.error(
                `file upload failed - ${JSON.stringify({
                    fileFormat: fileTypeInfo?.exactType,
                    fileSize: convertBytesToHumanReadable(fileSize),
                })}`,
                e,
            );
        }
        const error = handleUploadError(e);
        switch (error.message) {
            case CustomError.ETAG_MISSING:
                return { fileUploadResult: UPLOAD_RESULT.BLOCKED };
            case CustomError.UNSUPPORTED_FILE_FORMAT:
                return { fileUploadResult: UPLOAD_RESULT.UNSUPPORTED };
            case CustomError.FILE_TOO_LARGE:
                return {
                    fileUploadResult:
                        UPLOAD_RESULT.LARGER_THAN_AVAILABLE_STORAGE,
                };
            default:
                return { fileUploadResult: UPLOAD_RESULT.FAILED };
        }
    }
}
