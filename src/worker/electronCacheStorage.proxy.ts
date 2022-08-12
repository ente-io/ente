import ElectronCacheStorage from 'services/electron/cache';
import * as Comlink from 'comlink';

export default class ElectronCacheStorageProxy {
    async open(cacheName: string) {
        const { match, put } = await ElectronCacheStorage.open(cacheName);
        return Comlink.proxy({
            match: Comlink.proxy(match),
            put: Comlink.proxy(put),
        });
    }

    async delete(cacheName: string) {
        return await ElectronCacheStorage.delete(cacheName);
    }
}
