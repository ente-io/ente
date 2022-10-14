import { ipcRenderer } from 'electron/renderer';
import { isPlatformMac } from '../utils/main';

export async function convertHEIC(fileData: Uint8Array): Promise<Uint8Array> {
    if (!isPlatformMac()) {
        throw Error('native heic conversion only supported on mac');
    }
    const convertedFileData = await ipcRenderer.invoke(
        'convert-heic',
        fileData
    );
    return convertedFileData;
}
