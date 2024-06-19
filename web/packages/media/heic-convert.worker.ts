import { expose } from "comlink";
import HeicConvert from "heic-convert";

export class HEICConvertWorker {
    /**
     * Convert a HEIC file to a JPEG file.
     *
     * Both the input and output are blobs.
     */
    async heicToJPEG(heicBlob: Blob) {
        return heicToJPEG(heicBlob);
    }
}

expose(HEICConvertWorker);

const heicToJPEG = async (heicBlob: Blob): Promise<Blob> => {
    const buffer = new Uint8Array(await heicBlob.arrayBuffer());
    const result = await HeicConvert({ buffer, format: "JPEG" });
    const convertedData = new Uint8Array(result);
    return new Blob([convertedData], { type: "image/jpeg" });
};
