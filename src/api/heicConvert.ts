import { ipcRenderer } from 'electron/renderer';

export async function convertHEIC(fileData: Uint8Array): Promise<Uint8Array> {
    const convertedFileData = await ipcRenderer.invoke(
        'convert-heic',
        fileData
    );
    return convertedFileData;
}
