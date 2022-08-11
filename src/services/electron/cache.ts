import { runningInBrowser } from 'utils/common';

class ElectronCacheService {
    private ElectronAPIs: any;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.openDiskCache;
    }
    async open(cacheName: string): Promise<Cache> {
        if (this.allElectronAPIsExist) {
            return await this.ElectronAPIs.openDiskCache(cacheName);
        }
    }

    async delete(cacheName: string): Promise<boolean> {
        if (this.allElectronAPIsExist) {
            return await this.ElectronAPIs.deleteDiskCache(cacheName);
        }
    }
}

export default new ElectronCacheService();
