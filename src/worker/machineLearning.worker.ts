import { expose } from 'comlink';
import { EnteFile } from 'types/file';
import mlService from 'services/machineLearning/machineLearningService';
import { MachineLearningWorker } from 'types/machineLearning';
import { pipeConsoleLogsToDebugLogs } from 'utils/logging';
// import ReverseProxiedElectronCacheStorageProxy from './electronCacheStorageProxy.proxy';
// import { setupResponseComlinkTransferHandler } from 'utils/comlink';

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {
        pipeConsoleLogsToDebugLogs();
        // this.init();
    }

    // public async init() {
    //     const recp = new ReverseProxiedElectronCacheStorageProxy();
    //     const cacheProxy = await recp.open('thumbs');

    //     const thumb = await cacheProxy.match('13578875');
    //     console.log('worker init cache.match', thumb);
    // }

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

// setupResponseComlinkTransferHandler();
