import { ElectronAPIs } from 'types/electron';
import { logError } from 'utils/sentry';

class ElectronHEICConverter {
    private electronAPIs: ElectronAPIs;
    private allElectronAPIExists: boolean;
    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
        this.allElectronAPIExists = !!this.electronAPIs?.convertHEIC;
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    async convert(fileBlob: Blob, format = 'JPEG'): Promise<Blob> {
        try {
            if (this.allElectronAPIExists) {
                const inputFileData = new Uint8Array(
                    await fileBlob.arrayBuffer()
                );
                const convertedFileData = await this.electronAPIs.convertHEIC(
                    inputFileData
                );
                return new Blob([convertedFileData]);
            }
        } catch (e) {
            logError(e, 'failed to convert heic natively');
        }
    }
}

export default new ElectronHEICConverter();
