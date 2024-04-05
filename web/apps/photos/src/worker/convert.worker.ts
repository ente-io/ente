import * as Comlink from "comlink";

export class DedicatedConvertWorker {
    async convertHEICToJPEG(fileBlob: Blob) {
        return this.convertHEICToJPEG(fileBlob);
    }
}

Comlink.expose(DedicatedConvertWorker, self);
