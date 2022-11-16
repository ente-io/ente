import { ipcRenderer } from 'electron';
import { ElectronFile } from '../types';

export async function runFFmpegCmd(
    cmd: string[],
    inputFile: File | ElectronFile,
    outputFileName: string
) {
    let inputFilePath = null;
    let inputFileData = null;
    let inputFileName = null;
    if (!inputFile.path) {
        inputFileData = new Uint8Array(await inputFile.arrayBuffer());
        inputFileName = inputFile.name;
    } else {
        inputFilePath = inputFile.path;
    }
    const outputFileData = await ipcRenderer.invoke(
        'run-ffmpeg-cmd',
        cmd,
        inputFilePath,
        inputFileData,
        inputFileName,
        outputFileName
    );
    return new File([outputFileData], outputFileName);
}
