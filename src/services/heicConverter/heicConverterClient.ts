import * as HeicConvert from 'heic-convert';

const WAIT_TIME_IN_MICROSECONDS = 60 * 1000;

export async function convertHEIC(
    fileBlob: Blob,
    format: string
): Promise<Blob> {
    const filedata = new Uint8Array(await fileBlob.arrayBuffer());
    setTimeout(() => {
        throw Error('wait time exceeded');
    }, WAIT_TIME_IN_MICROSECONDS);
    const result = await HeicConvert({ buffer: filedata, format });
    const convertedFileData = new Uint8Array(result);
    const convertedFileBlob = new Blob([convertedFileData]);
    return convertedFileBlob;
}
