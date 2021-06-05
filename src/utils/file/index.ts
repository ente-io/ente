import { File } from 'services/fileService';
import { runningInBrowser } from 'utils/common';

const TYPE_HEIC = 'heic';
const UNSUPPORTED_FORMATS = ['flv', 'mkv', '3gp', 'avi', 'wmv'];

export function downloadAsFile(filename: string, content: string) {
    const file = new Blob([content], {
        type: 'text/plain',
    });
    const a = document.createElement('a');
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
    return name.toLowerCase().endsWith(TYPE_HEIC);
}

export function sortFilesIntoCollections(files: File[]) {
    const collectionWiseFiles = new Map<number, File[]>();
    for (const file of files) {
        if (!collectionWiseFiles.has(file.collectionID)) {
            collectionWiseFiles.set(file.collectionID, []);
        }
        collectionWiseFiles.get(file.collectionID).push(file);
    }
    return collectionWiseFiles;
}

export function getSelectedFileIds(selectedFiles) {
    const filesIDs: number[] = [];
    for (const [key, val] of Object.entries(selectedFiles)) {
        if (typeof val === 'boolean' && val) {
            filesIDs.push(Number(key));
        }
    }
    return filesIDs;
}
export function getSelectedFiles(selectedFiles, files: File[]): File[] {
    const filesIDs = new Set(getSelectedFileIds(selectedFiles));
    const filesToDelete: File[] = [];
    for (const file of files) {
        if (filesIDs.has(file.id)) {
            filesToDelete.push(file);
        }
    }
    return filesToDelete;
}

export function checkFileFormatSupport(name :string) {
    for (const format of UNSUPPORTED_FORMATS) {
        if ( name.toLowerCase().endsWith(format)) {
            throw Error('unsupported format');
        }
    }
}

export function formatDate(date: number | Date) {
    const dateTimeFormat = new Intl.DateTimeFormat('en-IN', {
        weekday: 'short',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    });
    return dateTimeFormat.format(date);
}

export function formatDateTime(date: number | Date) {
    const dateTimeFormat = new Intl.DateTimeFormat('en-IN', {
        weekday: 'short',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    });
    const timeFormat = new Intl.DateTimeFormat('en-IN', {
        timeStyle: 'medium',
    });
    return `${dateTimeFormat.format(date)} ${timeFormat.format(date)}`;
}
