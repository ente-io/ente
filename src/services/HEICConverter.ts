import QueueProcessor from 'services/queueProcessor';
import { CustomError } from 'utils/error';
import { logError } from 'utils/sentry';

class HEICConverter {
    private convertProcessor = new QueueProcessor<Blob>(5);

    async convert(worker, fileBlob: Blob, format = 'JPEG'): Promise<Blob> {
        const response = this.convertProcessor.queueUpRequest(
            async () => await worker.convertHEIC(format, fileBlob)
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
