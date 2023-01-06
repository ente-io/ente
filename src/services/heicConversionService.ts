import { logError } from 'utils/sentry';
import WasmHEICConverterService from './wasmHeicConverter/wasmHEICConverterService';
import ElectronImageProcessorService from 'services/electron/imageProcessor';

class HeicConversionService {
    async convert(heicFileData: Blob): Promise<Blob> {
        try {
            if (ElectronImageProcessorService.convertAPIExists()) {
                try {
                    return await ElectronImageProcessorService.convertHEIC(
                        heicFileData
                    );
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
