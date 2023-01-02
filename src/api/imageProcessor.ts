import { ipcRenderer } from 'electron/renderer';
import { existsSync } from 'fs';
import { logError } from '../services/logging';
import { ElectronFile } from '../types';

export async function convertHEIC(fileData: Uint8Array): Promise<Uint8Array> {
    const convertedFileData = await ipcRenderer.invoke(
        'convert-heic',
        fileData
    );
    return convertedFileData;
}

export async function generateImageThumbnail(
    inputFile: File | ElectronFile,
    maxDimension: number
): Promise<Uint8Array> {
    let inputFilePath = null;
    let createdTempInputFile = null;
    try {
        if (!existsSync(inputFile.path)) {
            const inputFileData = new Uint8Array(await inputFile.arrayBuffer());
            inputFilePath = await ipcRenderer.invoke(
                'write-temp-file',
                inputFileData,
                inputFile.name
            );
            createdTempInputFile = true;
        } else {
            inputFilePath = inputFile.path;
        }
        const thumbnail = await ipcRenderer.invoke(
            'generate-image-thumbnail',
            inputFilePath,
            maxDimension
        );
        return thumbnail;
    } finally {
        if (createdTempInputFile) {
            try {
                await ipcRenderer.invoke('remove-temp-file', inputFilePath);
            } catch (e) {
                logError(e, 'failed to deleteTempFile');
            }
        }
    }
}
