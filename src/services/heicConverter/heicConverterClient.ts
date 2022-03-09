import * as HeicConvert from 'heic-convert';

const WAIT_TIME_IN_MICROSECONDS = 60 * 1000;

export async function convertHEIC(
    fileBlob: Blob,
    format: string
): Promise<Blob> {
    return await new Promise((resolve, reject) => {
        const main = async () => {
            const filedata = new Uint8Array(await fileBlob.arrayBuffer());
            const timeout = setTimeout(() => {
                reject(Error('wait time exceeded'));
            }, WAIT_TIME_IN_MICROSECONDS);
            console.time('convertHEIC');
            const result = await HeicConvert({ buffer: filedata, format });
            console.timeEnd('convertHEIC');
            clearTimeout(timeout);
            const convertedFileData = new Uint8Array(result);
            const convertedFileBlob = new Blob([convertedFileData]);
            resolve(convertedFileBlob);
        };
        main();
    });
}
