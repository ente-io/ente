import { logError } from 'utils/sentry';

class DesktopService {
    private ElectronAPIs: any;
    private allElectronAPIsExist: boolean = false;
    constructor() {
        this.ElectronAPIs = globalThis['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.getEncryptionKey;
    }

    async getEncryptionKey() {
        try {
            if (this.allElectronAPIsExist) {
                return (await this.ElectronAPIs.getEncryptionKey()) as string;
            }
        } catch (e) {
            logError(e, 'getEncryptionKey failed');
        }
    }

    async setEncryptionKey(encryptionKey: string) {
        try {
            if (this.allElectronAPIsExist) {
                return await this.ElectronAPIs.setEncryptionKey(encryptionKey);
            }
        } catch (e) {
            logError(e, 'setEncryptionKey failed');
        }
    }

    async clearElectronStore() {
        try {
            if (this.allElectronAPIsExist) {
                return await this.ElectronAPIs.clearElectronStore();
            }
        } catch (e) {
            logError(e, 'getEncryptionKey failed');
        }
    }
}
export default new DesktopService();
