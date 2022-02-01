import QueueProcessor from 'services/queueProcessor';
import { ConvertWorker } from 'utils/comlink';
import { CustomError } from 'utils/error';
import { logError } from 'utils/sentry';

class HEICConverter {
    private convertProcessor = new QueueProcessor<Blob>(5);
    private worker = null;

    async convert(fileBlob: Blob, format = 'JPEG'): Promise<Blob> {
        if (!this.worker) {
            this.worker = await new ConvertWorker();
        }
        const response = this.convertProcessor.queueUpRequest(
            async () => await this.worker.convertHEIC(fileBlob, format)
        );
        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            } else {
                logError(e, 'heic conversion failed');
                throw e;
            }
        }
    }
}

export default new HEICConverter();
