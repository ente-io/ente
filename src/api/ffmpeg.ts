import { ipcRenderer } from 'electron';
import { logErrorSentry } from '../services/sentry';
import { deleteTempFile, writeTempFile } from '../services/fs';
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
            inputFilePath = await writeTempFile(inputFileData, inputFile.name);
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
                deleteTempFile(inputFilePath);
            } catch (e) {
                logErrorSentry(e, 'failed to deleteTempFile');
            }
        }
    }
}
