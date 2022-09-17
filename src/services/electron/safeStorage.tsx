import { ElectronAPIs } from 'types/electron';
import { logError } from 'utils/sentry';

class SafeStorageService {
    private electronAPIs: ElectronAPIs;
    private allElectronAPIsExist: boolean = false;
    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.electronAPIs?.getEncryptionKey;
    }

    async getEncryptionKey() {
        try {
            if (this.allElectronAPIsExist) {
                return (await this.electronAPIs.getEncryptionKey()) as string;
            }
        } catch (e) {
            logError(e, 'getEncryptionKey failed');
        }
    }

    async setEncryptionKey(encryptionKey: string) {
        try {
            if (this.allElectronAPIsExist) {
                return await this.electronAPIs.setEncryptionKey(encryptionKey);
            }
        } catch (e) {
            logError(e, 'setEncryptionKey failed');
        }
    }

    async clearElectronStore() {
        try {
            if (this.allElectronAPIsExist) {
                return this.electronAPIs.clearElectronStore();
            }
        } catch (e) {
            logError(e, 'clearElectronStore failed');
        }
    }
}
export default new SafeStorageService();
