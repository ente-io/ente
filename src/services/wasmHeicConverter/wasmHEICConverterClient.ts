import heicConvert from 'heic-convert';
import { getUint8ArrayView } from 'services/readerService';

export async function convertHEIC(
    fileBlob: Blob,
    format: 'JPEG' | 'PNG'
): Promise<Blob> {
    const filedata = await getUint8ArrayView(fileBlob);
    const result = await heicConvert({ buffer: filedata, format });
    const convertedFileData = new Uint8Array(result);
    const convertedFileBlob = new Blob([convertedFileData]);
    return convertedFileBlob;
}
