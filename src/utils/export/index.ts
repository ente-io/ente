import { ExportRecord } from 'services/exportService';
import { File } from 'services/fileService';
import { MetadataObject } from 'services/uploadService';
import { formatDate } from 'utils/file';

export const getExportRecordFileUID = (file: File) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

export const getExportPendingFiles = async (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const queuedFiles = new Set(exportRecord?.queuedFiles);
    const unExportedFiles = allFiles.filter((file) => {
        if (queuedFiles.has(getExportRecordFileUID(file))) {
            return file;
        }
    });
    return unExportedFiles;
};

export const getFilesUploadedAfterLastExport = async (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const exportedFiles = new Set(exportRecord?.exportedFiles);
    const unExportedFiles = allFiles.filter((file) => {
        if (!exportedFiles.has(getExportRecordFileUID(file))) {
            return file;
        }
    });
    return unExportedFiles;
};

export const getExportFailedFiles = async (
    allFiles: File[],
    exportRecord: ExportRecord
) => {
    const failedFiles = new Set(exportRecord?.failedFiles);
    const filesToExport = allFiles.filter((file) => {
        if (failedFiles.has(getExportRecordFileUID(file))) {
            return file;
        }
    });
    return filesToExport;
};

export const dedupe = (files: any[]) => {
    const fileSet = new Set(files);
    const dedupedArray = new Array(...fileSet);
    return dedupedArray;
};

export const getGoogleLikeMetadataFile = (
    uid: string,
    metadata: MetadataObject
) => {
    const creationTime = metadata.creationTime / 1000000;
    const modificationTime = metadata.modificationTime / 1000000;
    return JSON.stringify(
        {
            title: uid,
            creationTime: {
                timestamp: creationTime,
                formatted: formatDate(creationTime),
            },
            modificationTime: {
                timestamp: modificationTime,
                formatted: formatDate(modificationTime),
            },
            geoData: {
                latitude: metadata.latitude,
                longitude: metadata.longitude,
            },
        },
        null,
        2
    );
};
