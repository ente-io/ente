import { FileWithCollection, Metadata } from 'types/upload';
import { EnteFile } from 'types/file';
import { FILE_TYPE } from 'constants/file';
import { getFileTypeFromFileObject } from 'services/upload/readFileService';
import { splitFilenameAndExtension } from 'utils/file';

const TYPE_JSON = 'json';

export function fileAlreadyInCollection(
    existingFilesInCollection: EnteFile[],
    newFileMetadata: Metadata
): boolean {
    for (const existingFile of existingFilesInCollection) {
        if (areFilesSame(existingFile.metadata, newFileMetadata)) {
            return true;
        }
    }
    return false;
}
export function areFilesSame(
    existingFile: Metadata,
    newFile: Metadata
): boolean {
    if (
        existingFile.fileType === newFile.fileType &&
        existingFile.creationTime === newFile.creationTime &&
        existingFile.modificationTime === newFile.modificationTime &&
        existingFile.title === newFile.title
    ) {
        return true;
    } else {
        return false;
    }
}

export function segregateFiles(
    filesWithCollectionToUpload: FileWithCollection[]
) {
    filesWithCollectionToUpload = filesWithCollectionToUpload.sort(
        (fileWithCollection1, fileWithCollection2) =>
            fileWithCollection1.file.name.localeCompare(
                fileWithCollection2.file.name
            )
    );
    const metadataFiles: FileWithCollection[] = [];
    const mediaFiles: FileWithCollection[] = [];
    filesWithCollectionToUpload.forEach((fileWithCollection) => {
        const file = fileWithCollection.file;
        if (file.name.startsWith('.')) {
            // ignore files with name starting with . (hidden files)
            return;
        }
        if (file.name.toLowerCase().endsWith(TYPE_JSON)) {
            metadataFiles.push(fileWithCollection);
        } else {
            mediaFiles.push(fileWithCollection);
        }
    });
    const normalFiles: FileWithCollection[] = [];
    const livePhotoFiles: FileWithCollection[] = [];
    for (let i = 0; i < mediaFiles.length - 1; i++) {
        const mediaFile1 = mediaFiles[i];
        const mediaFile2 = mediaFiles[i + 1];
        if (mediaFile1.collectionID === mediaFile2.collectionID) {
            const collectionID = mediaFiles[i].collectionID;
            const file1 = mediaFile1.file;
            const file2 = mediaFile2.file;
            const file1Type = getFileTypeFromFileObject(file1);
            const file2Type = getFileTypeFromFileObject(file2);
            if (
                file1Type !== FILE_TYPE.OTHERS &&
                file2Type !== FILE_TYPE.OTHERS
            ) {
                let imageFile;
                let videoFile;
                if (
                    file1Type !== file2Type &&
                    splitFilenameAndExtension(file1.name)[0] ===
                        splitFilenameAndExtension(file2.name)[0]
                ) {
                    if (
                        file1Type === FILE_TYPE.IMAGE &&
                        file2Type === FILE_TYPE.VIDEO
                    ) {
                        imageFile = file1;
                        videoFile = file2;
                    } else {
                        imageFile = file2;
                        videoFile = file1;
                    }
                    livePhotoFiles.push({
                        collectionID: collectionID,
                        isLivePhoto: true,
                        livePhotoAssets: { image: imageFile, video: videoFile },
                    });
                }
            }
        } else {
            normalFiles.push(mediaFile1);
            normalFiles.push(mediaFile2);
        }
    }
    return { mediaFiles: { normalFiles, livePhotoFiles }, metadataFiles };
}

export function addKeysToFilesToBeUploaded(files: FileWithCollection[]) {
    console.log(files);
    return files.map((file) => ({
        ...file,
        key: getFileToBeUploadedKey(file),
    }));
}

function getFileToBeUploadedKey(fileWithCollection: FileWithCollection) {
    const fileName = splitFilenameAndExtension(
        fileWithCollection.isLivePhoto
            ? fileWithCollection.livePhotoAssets[0].name + '-livePhoto'
            : fileWithCollection.file.name
    )[0];
    return fileName;
}
