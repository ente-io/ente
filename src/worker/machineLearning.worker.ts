import { expose, wrap } from 'comlink';
import { EnteFile } from 'types/file';
import mlService from 'services/machineLearning/machineLearningService';
import { MachineLearningWorker } from 'types/machineLearning';
import { setupResponseComlinkTransferHandler } from 'utils/comlink';

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {
        this.init();
    }

    public async init() {
        const ElectronCacheStorageProxy = wrap(self) as any;
        const proxiedElectronCacheService =
            await new ElectronCacheStorageProxy();

        const cacheProxy = await proxiedElectronCacheService.open('thumbs');
        // const cache = await cacheProxy;
        // const cacheMatch = await cache.match;
        // console.log('worker init openDiskCache', cache);
        const thumb = await cacheProxy.match('13578875');
        console.log('worker init cache.match', thumb);
    }

    public async closeLocalSyncContext() {
        return mlService.closeLocalSyncContext();
    }

    public async syncLocalFile(
        token: string,
        enteFile: EnteFile,
        localFile: globalThis.File
    ) {
        return mlService.syncLocalFile(token, enteFile, localFile);
    }

    public async sync(token: string) {
        return mlService.sync(token);
    }

    public close() {
        self.close();
    }
}

expose(DedicatedMLWorker, self);

setupResponseComlinkTransferHandler();
