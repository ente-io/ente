import * as Comlink from 'comlink';
import { convertHEIC } from 'services/wasmHeicConverter/wasmHEICConverterClient';

export class DedicatedConvertWorker {
    async convertHEIC(fileBlob: Blob, format: 'JPEG' | 'PNG') {
        return convertHEIC(fileBlob, format);
    }
}

Comlink.expose(DedicatedConvertWorker, self);
