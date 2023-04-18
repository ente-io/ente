import * as HeicConvert from 'heic-convert';
import { getUint8ArrayView } from 'services/readerService';

export async function convertHEIC(
    fileBlob: Blob,
    format: string
): Promise<Blob> {
    const filedata = await getUint8ArrayView(fileBlob);
    const result = await HeicConvert({ buffer: filedata, format });
    const convertedFileData = new Uint8Array(result);
    const convertedFileBlob = new Blob([convertedFileData]);
    return convertedFileBlob;
}
