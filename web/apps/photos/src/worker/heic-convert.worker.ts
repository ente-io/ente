import { expose } from "comlink";
import HeicConvert from "heic-convert";
import { getUint8ArrayView } from "services/readerService";

export class DedicatedHEICConvertWorker {
    async heicToJPEG(heicBlob: Blob) {
        return heicToJPEG(heicBlob);
    }
}

expose(DedicatedHEICConvertWorker, self);

/**
 * Convert a HEIC file to a JPEG file.
 *
 * Both the input and output are blobs.
 */
export const heicToJPEG = async (heicBlob: Blob): Promise<Blob> => {
    const filedata = await getUint8ArrayView(heicBlob);
    const result = await HeicConvert({ buffer: filedata, format: "JPEG" });
    const convertedFileData = new Uint8Array(result);
    const convertedFileBlob = new Blob([convertedFileData]);
    return convertedFileBlob;
};
