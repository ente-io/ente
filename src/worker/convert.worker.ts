import * as Comlink from 'comlink';
import { convertHEIC } from 'services/wasmHeicConverter/wasmHEICConverterClient.ts';

export class DedicatedConvertWorker {
    async convertHEIC(fileBlob: Blob, format: string) {
        return convertHEIC(fileBlob, format);
    }
}

Comlink.expose(DedicatedConvertWorker, self);
