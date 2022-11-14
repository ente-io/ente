import { ipcRenderer } from 'electron';
import { ElectronFile } from '../types';

export async function runFFmpegCmd(
    cmd: string[],
    inputFile: File | ElectronFile,
    outputFileName: string
) {
    let inputFilePath = null;
    let inputFileData = null;
    if (inputFile instanceof File) {
        inputFileData = new Uint8Array(await inputFile.arrayBuffer());
    } else {
        inputFilePath = inputFile.path;
    }
    const outputFileData = await ipcRenderer.invoke(
        'run-ffmpeg-cmd',
        cmd,
        inputFilePath,
        inputFileData,
        outputFileName
    );
    return new File([outputFileData], outputFileName);
}
