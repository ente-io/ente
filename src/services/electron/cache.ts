import { runningInBrowser } from 'utils/common';

class ElectronCacheService {
    private ElectronAPIs: any;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.openLocalCache;
    }
    async open(cacheName: string) {
        if (this.allElectronAPIsExist) {
            return await this.ElectronAPIs.openLocalCache(cacheName);
        }
    }
}

export default new ElectronCacheService();
