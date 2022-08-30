import { ElectronAPIs } from 'types/electron';
import { runningInBrowser } from 'utils/common';
import { logError } from 'utils/sentry';

class SafeStorageService {
    private ElectronAPIs: ElectronAPIs;
    private allElectronAPIsExist: boolean = false;
    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
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
                return this.ElectronAPIs.clearElectronStore();
            }
        } catch (e) {
            logError(e, 'clearElectronStore failed');
        }
    }
}
export default new SafeStorageService();
