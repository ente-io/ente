import * as HeicConvert from 'heic-convert';

export async function convertHEIC2JPEG(fileBlob: Blob): Promise<Blob> {
    const filedata = new Uint8Array(await fileBlob.arrayBuffer());
    const result = await HeicConvert({ buffer: filedata, format: 'PNG' });
    const convertedFileData = new Uint8Array(result);
    const convertedFileBlob = new Blob([convertedFileData]);
    return convertedFileBlob;
}
