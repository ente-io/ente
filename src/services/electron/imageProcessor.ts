import { ElectronAPIs } from 'types/electron';
import { ElectronFile } from 'types/upload';
import { convertBytesToHumanReadable } from 'utils/file/size';
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
                `originalFileSize:${convertBytesToHumanReadable(
                    fileBlob?.size
                )},convertedFileSize:${convertBytesToHumanReadable(
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
        maxDimension: number,
        maxSize: number
    ): Promise<Uint8Array> {
        try {
            if (!this.electronAPIs?.generateImageThumbnail) {
                throw new Error('generateImageThumbnail API not available');
            }
            const startTime = Date.now();
            const thumb = await this.electronAPIs.generateImageThumbnail(
                inputFile,
                maxDimension,
                maxSize
            );
            addLogLine(
                `originalFileSize:${convertBytesToHumanReadable(
                    inputFile?.size
                )},thumbFileSize:${convertBytesToHumanReadable(
                    thumb?.length
                )},  native thumbnail generation time: ${
                    Date.now() - startTime
                }ms `
            );
            return thumb;
        } catch (e) {
            logError(e, 'failed to generate image thumbnail natively');
            throw e;
        }
    }
}

export default new ElectronImageProcessorService();
