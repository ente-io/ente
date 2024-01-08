import { expose } from 'comlink';
import { EnteFile } from 'types/file';
import mlService from 'services/machineLearning/machineLearningService';
import { MachineLearningWorker } from 'types/machineLearning';
import { addLogLine } from '@ente/shared/logging';
// import ReverseProxiedElectronCacheStorageProxy from './electronCacheStorageProxy.proxy';
// import { setupResponseComlinkTransferHandler } from 'utils/comlink';

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {
        addLogLine('DedicatedMLWorker constructor called');
        // this.init();
    }

    // public async init() {
    //     const recp = new ReverseProxiedElectronCacheStorageProxy();
    //     const cacheProxy = await recp.open('thumbs');

    //     const thumb = await cacheProxy.match('13578875');
    //     addLogLine('worker init cache.match', thumb);
    // }

    public async closeLocalSyncContext() {
        return mlService.closeLocalSyncContext();
    }

    public async syncLocalFile(
        token: string,
        userID: number,
        enteFile: EnteFile,
        localFile: globalThis.File
    ) {
        return mlService.syncLocalFile(token, userID, enteFile, localFile);
    }

    public async sync(token: string, userID: number) {
        return mlService.sync(token, userID);
    }

    public async regenerateFaceCrop(
        token: string,
        userID: number,
        faceID: string
    ) {
        return mlService.regenerateFaceCrop(token, userID, faceID);
    }

    public close() {
        self.close();
    }
}

expose(DedicatedMLWorker, self);

// setupResponseComlinkTransferHandler();
