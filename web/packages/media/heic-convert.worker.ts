import { expose } from "comlink";
import { logUnhandledErrorsAndRejectionsInWorker } from "ente-base/log-web";
import { wait } from "ente-utils/promise";
import HeicConvert from "heic-convert";

export class HEICConvertWorker {
    /**
     * Convert a HEIC file to a JPEG file.
     *
     * Both the input and output are blobs.
     */
    async heicToJPEG(heicBlob: Blob) {
        const output = await heicToJPEG(heicBlob);
        // I'm told this library used to have big memory spikes, and adding
        // pauses to get GC to run helped. This might just be superstition tho.
        await wait(10 /* ms */);
        return output;
    }
}

expose(HEICConvertWorker);

logUnhandledErrorsAndRejectionsInWorker();

const heicToJPEG = async (heicBlob: Blob): Promise<Blob> => {
    const buffer = new Uint8Array(await heicBlob.arrayBuffer());
    // [Note: Revisit some Node.js types errors post 22 upgrade]
    //
    // Going beyond "typescript" "5.6.3" we start seeing a type error here. This
    // is possibly fixed in the newer Node.js types, but we're at 20 currently.
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const result = await HeicConvert({ buffer, format: "JPEG" });
    const convertedData = new Uint8Array(result);
    return new Blob([convertedData], { type: "image/jpeg" });
};
