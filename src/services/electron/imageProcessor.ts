import { ElectronAPIs } from 'types/electron';
import { ElectronFile } from 'types/upload';
import { makeHumanReadableStorage } from 'utils/billing';
import { addLogLine } from 'utils/logging';
import { logError } from 'utils/sentry';

class ElectronImageProcessorService {
    private electronAPIs: ElectronAPIs;
    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
    }

    convertAPIExists() {
        return !!this.electronAPIs?.convertHEIC;
    }

    generateImageThumbnailAPIExists() {
        return !!this.electronAPIs?.generateImageThumbnail;
    }

    async convertHEIC(fileBlob: Blob): Promise<Blob> {
        try {
            if (!this.electronAPIs?.convertHEIC) {
                throw new Error('convertHEIC API not available');
            }
            const startTime = Date.now();
            const inputFileData = new Uint8Array(await fileBlob.arrayBuffer());
            const convertedFileData = await this.electronAPIs.convertHEIC(
                inputFileData
            );
            addLogLine(
                `originalFileSize:${makeHumanReadableStorage(
                    fileBlob?.size
                )},convertedFileSize:${makeHumanReadableStorage(
                    convertedFileData?.length
                )},  native heic conversion time: ${Date.now() - startTime}ms `
            );
            return new Blob([convertedFileData]);
        } catch (e) {
            logError(e, 'failed to convert heic natively');
            throw e;
        }
    }

    async generateImageThumbnail(
        inputFile: File | ElectronFile,
        maxDimension: number
    ): Promise<Uint8Array> {
        try {
            if (!this.electronAPIs?.generateImageThumbnail) {
                throw new Error('generateImageThumbnail API not available');
            }
            return await this.electronAPIs.generateImageThumbnail(
                inputFile,
                maxDimension
            );
        } catch (e) {
            logError(e, 'failed to generate image thumbnail natively');
            throw e;
        }
    }
}

export default new ElectronImageProcessorService();
