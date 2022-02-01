import * as Comlink from 'comlink';
import { convertHEIC } from 'utils/file/convertHEIC';

export class Convert {
    async convertHEIC(format, file) {
        return convertHEIC(format, file);
    }
}

Comlink.expose(Convert);
