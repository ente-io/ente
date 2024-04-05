import HeicConvert from "heic-convert";
import { getUint8ArrayView } from "services/readerService";

/**
 * Convert a HEIC file to a JPEG file.
 *
 * Both the input and output are blobs.
 */
export const convertHEICToJPEG = async (heicBlob: Blob): Promise<Blob> => {
    const filedata = await getUint8ArrayView(heicBlob);
    const result = await HeicConvert({ buffer: filedata, format: "JPEG" });
    const convertedFileData = new Uint8Array(result);
    const convertedFileBlob = new Blob([convertedFileData]);
    return convertedFileBlob;
};
