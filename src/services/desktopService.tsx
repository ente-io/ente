import { runningInBrowser } from 'utils/common';

class DesktopService {
    private ElectronAPIs: any;
    private allElectronAPIsExist: boolean = false;
    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs.getEncryptionKey;
    }

    async getEncryptionKey() {
        console.log(this.allElectronAPIsExist, this.ElectronAPIs);
        if (this.allElectronAPIsExist) {
            return (await this.ElectronAPIs.getEncryptionKey()) as string;
        }
    }

    async setEncryptionKey(encryptionKey: string) {
        console.log(this.allElectronAPIsExist, this.ElectronAPIs);
        if (this.allElectronAPIsExist) {
            console.log(encryptionKey);
            return await this.ElectronAPIs.setEncryptionKey(encryptionKey);
        }
    }
}
export default new DesktopService();
