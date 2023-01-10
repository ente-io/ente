import { ipcRenderer } from 'electron';
import { existsSync } from 'fs';
import { writeStream } from '../services/fs';
import { logError } from '../services/logging';
import { ElectronFile } from '../types';

export async function runFFmpegCmd(
    cmd: string[],
    inputFile: File | ElectronFile,
    outputFileName: string
) {
    let inputFilePath = null;
    let createdTempInputFile = null;
    try {
        if (!existsSync(inputFile.path)) {
            const tempFilePath = await ipcRenderer.invoke('get-temp-file-path');
            inputFilePath = writeStream(tempFilePath, await inputFile.stream());
            createdTempInputFile = true;
        } else {
            inputFilePath = inputFile.path;
        }
        const outputFileData = await ipcRenderer.invoke(
            'run-ffmpeg-cmd',
            cmd,
            inputFilePath,
            outputFileName
        );
        return new File([outputFileData], outputFileName);
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
