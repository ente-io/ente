import { logError } from "@ente/shared/sentry";
import WasmHEICConverterService from "./wasmHeicConverter/wasmHEICConverterService";

class HeicConversionService {
    async convert(heicFileData: Blob): Promise<Blob> {
        try {
            return await WasmHEICConverterService.convert(heicFileData);
        } catch (e) {
            logError(e, "failed to convert heic file");
            throw e;
        }
    }
}
export default new HeicConversionService();
