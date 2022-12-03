import { ipcRenderer } from 'electron/renderer';
import { isPlatform } from '../utils/preload';

export async function convertHEIC(fileData: Uint8Array): Promise<Uint8Array> {
    if (!isPlatform('mac')) {
        throw Error('native heic conversion only supported on mac');
    }
    const convertedFileData = await ipcRenderer.invoke(
        'convert-heic',
        fileData
    );
    return convertedFileData;
}
