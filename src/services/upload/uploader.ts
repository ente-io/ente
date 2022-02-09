import { File, FILE_TYPE } from 'services/fileService';
import { sleep } from 'utils/common';
import { handleUploadError, CustomError } from 'utils/common/errorUtil';
import { decryptFile, splitFilenameAndExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { fileAlreadyInCollection } from 'utils/upload';
import UploadHttpClient from './uploadHttpClient';
import UIService from './uiService';
import { FileUploadResults, FileWithCollection } from './uploadManager';
import UploadService, {
    BackupedFile,
    EncryptedFile,
    FileInMemory,
    FileWithMetadata,
    isDataStream,
    MetadataObject,
    UploadFile,
} from './uploadService';
import uploadService from './uploadService';
import { FileTypeInfo, getFileType } from './readFileService';
import { encodeMotionPhoto } from 'services/motionPhotoService';

const TwoSecondInMillSeconds = 2000;
const FIVE_GB_IN_BYTES = 5 * 1024 * 1024 * 1024;
interface UploadResponse {
    fileUploadResult: FileUploadResults;
    file?: File;
}
export default async function uploader(
    worker: any,
    existingFilesInCollection: File[],
    fileWithCollection: FileWithCollection
): Promise<UploadResponse> {
    const {
        file: rawFile,
        isLivePhoto,
        livePhotoAsset,
        collection,
        key: progressBarKey,
    } = fileWithCollection;

    let file: FileInMemory = null;
    let encryptedFile: EncryptedFile = null;
    let metadata: MetadataObject = null;
    let fileTypeInfo: FileTypeInfo = null;
    let fileWithMetadata: FileWithMetadata = null;

    UIService.setFileProgress(progressBarKey, 0);
    const fileSize = isLivePhoto
        ? livePhotoAsset[0].size + livePhotoAsset[1].size
        : rawFile.size;
    try {
        if (fileSize >= FIVE_GB_IN_BYTES) {
            UIService.setFileProgress(
                progressBarKey,
                FileUploadResults.TOO_LARGE
            );
            // wait two second before removing the file from the progress in file section
            await sleep(TwoSecondInMillSeconds);
            return { fileUploadResult: FileUploadResults.TOO_LARGE };
        }
        if (isLivePhoto) {
            const file1TypeInfo = await getFileType(worker, livePhotoAsset[0]);
            const file2TypeInfo = await getFileType(worker, livePhotoAsset[1]);
            fileTypeInfo = {
                fileType: FILE_TYPE.LIVE_PHOTO,
                exactType: `${file1TypeInfo.exactType}+${file2TypeInfo.exactType}`,
            };
            let imageFile: globalThis.File;
            let videoFile: globalThis.File;

            const imageMetadata = await uploadService.getFileMetadata(
                imageFile,
                collection,
                fileTypeInfo
            );
            const videoMetadata = await uploadService.getFileMetadata(
                videoFile,
                collection,
                fileTypeInfo
            );
            metadata = {
                ...videoMetadata,
                ...imageMetadata,
                title: splitFilenameAndExtension(livePhotoAsset[0].name)[0],
            };
            if (fileAlreadyInCollection(existingFilesInCollection, metadata)) {
                UIService.setFileProgress(
                    progressBarKey,
                    FileUploadResults.SKIPPED
                );
                // wait two second before removing the file from the progress in file section
                await sleep(TwoSecondInMillSeconds);
                return { fileUploadResult: FileUploadResults.SKIPPED };
            }
            const image = await UploadService.readFile(
                worker,
                imageFile,
                fileTypeInfo
            );
            const video = await UploadService.readFile(
                worker,
                videoFile,
                fileTypeInfo
            );

            if (isDataStream(video.filedata) || isDataStream(image.filedata)) {
                throw new Error('too large live photo assets');
            }
            file = {
                filedata: await encodeMotionPhoto({
                    image: image.filedata as Uint8Array,
                    video: video.filedata as Uint8Array,
                    imageNameTitle: imageFile.name,
                    videoNameTitle: videoFile.name,
                }),
                thumbnail: video.hasStaticThumbnail
                    ? video.thumbnail
                    : image.thumbnail,
                hasStaticThumbnail: !(
                    !video.hasStaticThumbnail || !image.hasStaticThumbnail
                ),
            };
        } else {
            fileTypeInfo = await getFileType(worker, rawFile);
            if (fileTypeInfo.fileType === FILE_TYPE.OTHERS) {
                throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);
            }
            metadata = await uploadService.getFileMetadata(
                rawFile,
                collection,
                fileTypeInfo
            );

            if (fileAlreadyInCollection(existingFilesInCollection, metadata)) {
                UIService.setFileProgress(
                    progressBarKey,
                    FileUploadResults.SKIPPED
                );
                // wait two second before removing the file from the progress in file section
                await sleep(TwoSecondInMillSeconds);
                return { fileUploadResult: FileUploadResults.SKIPPED };
            }

            file = await UploadService.readFile(worker, rawFile, fileTypeInfo);
        }
        if (file.hasStaticThumbnail) {
            metadata.hasStaticThumbnail = true;
        }
        fileWithMetadata = {
            filedata: file.filedata,
            thumbnail: file.thumbnail,
            metadata,
        };

        encryptedFile = await UploadService.encryptFile(
            worker,
            fileWithMetadata,
            collection.key
        );

        const backupedFile: BackupedFile = await UploadService.uploadToBucket(
            encryptedFile.file
        );

        const uploadFile: UploadFile = UploadService.getUploadFile(
            collection,
            backupedFile,
            encryptedFile.fileKey
        );

        const uploadedFile = await UploadHttpClient.uploadFile(uploadFile);
        const decryptedFile = await decryptFile(uploadedFile, collection);

        UIService.setFileProgress(progressBarKey, FileUploadResults.UPLOADED);
        UIService.increaseFileUploaded();
        return {
            fileUploadResult: FileUploadResults.UPLOADED,
            file: decryptedFile,
        };
    } catch (e) {
        logError(e, 'file upload failed', {
            fileFormat: fileTypeInfo.exactType,
        });
        const error = handleUploadError(e);
        switch (error.message) {
            case CustomError.ETAG_MISSING:
                UIService.setFileProgress(
                    progressBarKey,
                    FileUploadResults.BLOCKED
                );
                return { fileUploadResult: FileUploadResults.BLOCKED };
            case CustomError.UNSUPPORTED_FILE_FORMAT:
                UIService.setFileProgress(
                    progressBarKey,
                    FileUploadResults.UNSUPPORTED
                );
                return { fileUploadResult: FileUploadResults.UNSUPPORTED };

            case CustomError.FILE_TOO_LARGE:
                UIService.setFileProgress(
                    progressBarKey,
                    FileUploadResults.TOO_LARGE
                );
                return { fileUploadResult: FileUploadResults.TOO_LARGE };
            default:
                UIService.setFileProgress(
                    progressBarKey,
                    FileUploadResults.FAILED
                );
                return { fileUploadResult: FileUploadResults.FAILED };
        }
    } finally {
        file = null;
        fileWithMetadata = null;
        encryptedFile = null;
    }
}
