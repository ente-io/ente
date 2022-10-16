import { ElectronAPIs } from 'types/electron';
import { makeHumanReadableStorage } from 'utils/billing';
import { addLogLine } from 'utils/logging';
import { logError } from 'utils/sentry';

class ElectronHEICConverter {
    private electronAPIs: ElectronAPIs;
    private allElectronAPIExists: boolean;
    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
        this.allElectronAPIExists = !!this.electronAPIs?.convertHEIC;
    }

    apiExists() {
        return this.allElectronAPIExists;
    }

    async convert(fileBlob: Blob): Promise<Blob> {
        try {
            if (this.allElectronAPIExists) {
                const startTime = Date.now();
                const inputFileData = new Uint8Array(
                    await fileBlob.arrayBuffer()
                );
                const convertedFileData = await this.electronAPIs.convertHEIC(
                    inputFileData
                );
                addLogLine(
                    `originalFileSize:${makeHumanReadableStorage(
                        fileBlob?.size
                    )},convertedFileSize:${makeHumanReadableStorage(
                        convertedFileData?.length
                    )},  native heic conversion time: ${
                        Date.now() - startTime
                    }ms `
                );
                return new Blob([convertedFileData]);
            }
        } catch (e) {
            logError(e, 'failed to convert heic natively');
            throw e;
        }
    }
}

export default new ElectronHEICConverter();
