import { LimitedCache, LimitedCacheStorage } from 'types/cache';

class ElectronCacheStorage implements LimitedCacheStorage {
    private ElectronAPIs: any;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.ElectronAPIs = globalThis['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.openDiskCache;
    }

    async open(cacheName: string): Promise<LimitedCache> {
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

export default new ElectronCacheStorage();
