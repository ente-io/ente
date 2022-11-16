import { ipcRenderer } from 'electron';
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
        if (!inputFile.path) {
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
