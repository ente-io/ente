import { ExportRecord } from 'services/exportService';
import { File } from 'services/fileService';


export const getFileUID = (file: File) => `${file.id}_${file.collectionID}`;


export const getExportPendingFiles = async (allFiles: File[], exportRecord: ExportRecord) => {
    const exportedFiles = new Set(exportRecord?.exportedFiles);
    const failedFiles = new Set(exportRecord?.failedFiles);
    const unExportedFiles = allFiles.filter((file) => {
        const fileUID = `${file.id}_${file.collectionID}`;
        if (!exportedFiles.has(fileUID) && !failedFiles.has(fileUID)) {
            return file;
        }
    });
    return unExportedFiles;
};

export const getExportFailedFiles = async (allFiles: File[], exportRecord: ExportRecord) => {
    const failedFiles = new Set(exportRecord?.failedFiles);
    const filesToExport = allFiles.filter((file) => {
        if (failedFiles.has(`${file.id}_${file.collectionID}`)) {
            return file;
        }
    });
    return filesToExport;
};
