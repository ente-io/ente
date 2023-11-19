import ElectronAPIs from '@ente/shared/electron';
import { addLogLine } from '@ente/shared/logging';
import { logError } from '@ente/shared/sentry';
import { ElectronFile } from 'types/upload';
import { CustomError } from '@ente/shared/error';
import { convertBytesToHumanReadable } from '@ente/shared/utils/size';

class ElectronImageProcessorService {
    async convertToJPEG(fileBlob: Blob, filename: string): Promise<Blob> {
        try {
            const startTime = Date.now();
            const inputFileData = new Uint8Array(await fileBlob.arrayBuffer());
            const convertedFileData = await ElectronAPIs.convertToJPEG(
                inputFileData,
                filename
            );
            addLogLine(
                `originalFileSize:${convertBytesToHumanReadable(
                    fileBlob?.size
                )},convertedFileSize:${convertBytesToHumanReadable(
                    convertedFileData?.length
                )},  native conversion time: ${Date.now() - startTime}ms `
            );
            return new Blob([convertedFileData]);
        } catch (e) {
            if (
                e.message !==
                CustomError.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED
            ) {
                logError(e, 'failed to convert to jpeg natively');
            }
            throw e;
        }
    }

    async generateImageThumbnail(
        inputFile: File | ElectronFile,
        maxDimension: number,
        maxSize: number
    ): Promise<Uint8Array> {
        try {
            const startTime = Date.now();
            const thumb = await ElectronAPIs.generateImageThumbnail(
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
            if (
                e.message !==
                CustomError.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED
            ) {
                logError(e, 'failed to generate image thumbnail natively');
            }
            throw e;
        }
    }
}

export default new ElectronImageProcessorService();
