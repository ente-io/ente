import { LimitedCache, LimitedCacheStorage } from 'types/cache';
import { ElectronAPIs } from 'types/electron';

class ElectronCacheStorageService implements LimitedCacheStorage {
    private electronAPIs: ElectronAPIs;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.electronAPIs?.openDiskCache;
    }

    async open(cacheName: string): Promise<LimitedCache> {
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

export const ElectronCacheStorage = new ElectronCacheStorageService();
