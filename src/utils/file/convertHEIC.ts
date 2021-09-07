import * as HeicConvert from 'heic-convert';

export async function convertHEIC2JPEG(fileBlob: Blob): Promise<Blob> {
    try {
        const filedata = new Uint8Array(await fileBlob.arrayBuffer());
        console.log(filedata);
        const result = await HeicConvert({ buffer: filedata, format: 'JPEG' });
        const convertedFileData = new Uint8Array(result);
        const convertedFileBlob = new Blob([convertedFileData]);
        console.log(URL.createObjectURL(convertedFileBlob));
        return convertedFileBlob;
    } catch (e) {
        console.log(e);
    }
}
