import isElectron from 'is-electron';
import { logError } from 'utils/sentry';
import WasmHEICConverterService from './wasmHeicConverter/wasmHEICConverterService';
import ElectronHEICConvertor from 'services/electron/heicConvertor';

class HeicConversionService {
    async convert(heicFileData: Blob): Promise<Blob> {
        try {
            if (isElectron() && !ElectronHEICConvertor.apiExists()) {
                try {
                    return await ElectronHEICConvertor.convert(heicFileData);
                } catch (e) {
                    return await WasmHEICConverterService.convert(heicFileData);
                }
            } else {
                return await WasmHEICConverterService.convert(heicFileData);
            }
        } catch (e) {
            logError(e, 'failed to convert heic file');
            throw e;
        }
    }
}
export default new HeicConversionService();
