import * as Comlink from 'comlink';
import { convertHEIC } from 'services/heicConverter/heicConverterClient';

export class Convert {
    async convertHEIC(fileBlob, format) {
        return convertHEIC(fileBlob, format);
    }
}

Comlink.expose(Convert);
