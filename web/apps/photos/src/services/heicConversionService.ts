import log from "@/next/log";
import WasmHEICConverterService from "./heic-convert/service";

class HeicConversionService {
    async convert(heicFileData: Blob): Promise<Blob> {
        try {
            return await WasmHEICConverterService.convert(heicFileData);
        } catch (e) {
            log.error("failed to convert heic file", e);
            throw e;
        }
    }
}
export default new HeicConversionService();
