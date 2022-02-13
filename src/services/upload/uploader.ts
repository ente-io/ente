import { EnteFile } from 'types/file';
import { handleUploadError, CustomError } from 'utils/error';
import { decryptFile, splitFilenameAndExtension } from 'utils/file';
import { logError } from 'utils/sentry';
import { fileAlreadyInCollection } from 'utils/upload';
import UploadHttpClient from './uploadHttpClient';
import UIService from './uiService';
import UploadService from './uploadService';
import uploadService from './uploadService';
import { getFileType } from './readFileService';
import {
    BackupedFile,
    EncryptedFile,
    FileInMemory,
    FileTypeInfo,
    FileWithCollection,
    FileWithMetadata,
    isDataStream,
    Metadata,
    UploadFile,
} from 'types/upload';
import { FILE_TYPE } from 'constants/file';
import { FileUploadResults } from 'constants/upload';
import { encodeMotionPhoto } from 'services/motionPhotoService';

const FIVE_GB_IN_BYTES = 5 * 1024 * 1024 * 1024;
interface UploadResponse {
    fileUploadResult: FileUploadResults;
    file?: EnteFile;
}
export default async function uploader(
    worker: any,
    reader: FileReader,
    existingFilesInCollection: EnteFile[],
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
    let metadata: Metadata = null;
    let fileTypeInfo: FileTypeInfo = null;
    let fileWithMetadata: FileWithMetadata = null;

    UIService.setFileProgress(progressBarKey, 0);
    const fileSize = isLivePhoto
        ? livePhotoAsset[0].size + livePhotoAsset[1].size
        : rawFile.size;
    try {
        if (fileSize >= FIVE_GB_IN_BYTES) {
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
                return { fileUploadResult: FileUploadResults.ALREADY_UPLOADED };
            }
            const image = await UploadService.readFile(
                worker,
                reader,
                imageFile,
                fileTypeInfo
            );
            const video = await UploadService.readFile(
                worker,
                reader,
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
                return { fileUploadResult: FileUploadResults.ALREADY_UPLOADED };
            }

            file = await UploadService.readFile(
                worker,
                reader,
                rawFile,
                fileTypeInfo
            );
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
        const decryptedFile = await decryptFile(uploadedFile, collection.key);

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
                return { fileUploadResult: FileUploadResults.BLOCKED };
            case CustomError.UNSUPPORTED_FILE_FORMAT:
                return { fileUploadResult: FileUploadResults.UNSUPPORTED };
            case CustomError.FILE_TOO_LARGE:
                return {
                    fileUploadResult:
                        FileUploadResults.LARGER_THAN_AVAILABLE_STORAGE,
                };
            default:
                return { fileUploadResult: FileUploadResults.FAILED };
        }
    } finally {
        file = null;
        fileWithMetadata = null;
        encryptedFile = null;
    }
}
