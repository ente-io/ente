import { ipcRenderer } from 'electron';
import { ElectronFile } from '../types';

export async function runFFmpegCmd(
    cmd: string[],
    inputFile: ElectronFile,
    outputFileName: string
) {
    const fileData = await ipcRenderer.invoke(
        'run-ffmpeg-cmd',
        cmd,
        inputFile.path,
        outputFileName
    );
    return new File([fileData], outputFileName);
}
