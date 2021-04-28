import { deleteFiles, File } from 'services/fileService';
import { runningInBrowser } from 'utils/common';

const TYPE_HEIC = 'heic';

export function downloadAsFile(filename: string, content: string) {
    const file = new Blob([content], {
        type: 'text/plain',
    });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(file);
    a.download = filename;

    a.style.display = 'none';
    document.body.appendChild(a);

    a.click();

    a.remove();
}

export async function convertHEIC2JPEG(fileBlob: Blob): Promise<Blob> {
    const heic2any = runningInBrowser() && require('heic2any');
    return await heic2any({
        blob: fileBlob,
        toType: 'image/jpeg',
        quality: 1,
    });
}

export function fileIsHEIC(name: string) {
    return name.endsWith(TYPE_HEIC);
}

export function sortFilesIntoCollections(files: File[]) {
    const collectionWiseFiles = new Map<number, File[]>();
    for (let file of files) {
        if (!collectionWiseFiles.has(file.collectionID)) {
            collectionWiseFiles.set(file.collectionID, new Array<File>());
        }
        collectionWiseFiles.get(file.collectionID).push(file);
    }
    return collectionWiseFiles;
}

export function getSelectedFileIds(selectedFiles) {
    let filesIDs: number[] = [];
    for (let [key, val] of Object.entries(selectedFiles)) {
        if (typeof val === 'boolean' && val) {
            filesIDs.push(Number(key));
        }
    }
    return filesIDs;
}
export function getSelectedFiles(selectedFiles, files: File[]): File[] {
    let filesIDs = new Set(getSelectedFileIds(selectedFiles));
    let filesToDelete: File[] = [];
    for (let file of files) {
        if (filesIDs.has(file.id)) {
            filesToDelete.push(file);
        }
    }
    return filesToDelete;
}
