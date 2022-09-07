import { ElectronAPIs } from 'types/electron';
import { runningInBrowser } from 'utils/common';

class ElectronCacheService {
    private electronAPIs: ElectronAPIs;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.electronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.electronAPIs?.openDiskCache;
    }
    async open(cacheName: string): Promise<Cache> {
        if (this.allElectronAPIsExist) {
            return await this.electronAPIs.openDiskCache(cacheName);
        }
    }

    async delete(cacheName: string): Promise<boolean> {
        if (this.allElectronAPIsExist) {
            return await this.electronAPIs.deleteDiskCache(cacheName);
        }
    }
}

export default new ElectronCacheService();
