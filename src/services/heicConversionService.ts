import { logError } from 'utils/sentry';
import WasmHEICConverterService from './wasmHeicConverter/wasmHEICConverterService';
import ElectronImageMagickService from 'services/electron/imageMagick';

class HeicConversionService {
    async convert(heicFileData: Blob): Promise<Blob> {
        try {
            if (ElectronImageMagickService.convertAPIExists()) {
                try {
                    return await ElectronImageMagickService.convertHEIC(
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
