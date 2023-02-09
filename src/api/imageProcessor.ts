import { CustomErrors } from '../constants/errors';
import { ipcRenderer } from 'electron/renderer';
import { existsSync } from 'fs';
import { writeStream } from '../services/fs';
import { logError } from '../services/logging';
import { ElectronFile } from '../types';
import { isPlatform } from '../utils/common/platform';

export async function convertHEIC(fileData: Uint8Array): Promise<Uint8Array> {
    if (isPlatform('windows')) {
        throw Error(CustomErrors.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED);
    }
    const convertedFileData = await ipcRenderer.invoke(
        'convert-heic',
        fileData
    );
    return convertedFileData;
}

export async function generateImageThumbnail(
    inputFile: File | ElectronFile,
    maxDimension: number,
    maxSize: number
): Promise<Uint8Array> {
    let inputFilePath = null;
    let createdTempInputFile = null;
    try {
        if (isPlatform('windows')) {
            throw Error(
                CustomErrors.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED
            );
        }
        if (!existsSync(inputFile.path)) {
            const tempFilePath = await ipcRenderer.invoke(
                'get-temp-file-path',
                inputFile.name
            );
            await writeStream(tempFilePath, await inputFile.stream());
            inputFilePath = tempFilePath;
            createdTempInputFile = true;
        } else {
            inputFilePath = inputFile.path;
        }
        const thumbnail = await ipcRenderer.invoke(
            'generate-image-thumbnail',
            inputFilePath,
            maxDimension,
            maxSize
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
