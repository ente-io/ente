import { expose } from 'comlink';
import { File } from 'services/fileService';
import mlService from 'services/machineLearning/machineLearningService';
import { MachineLearningWorker, MLSyncConfig } from 'types/machineLearning';

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {}

    public async syncLocalFile(
        token: string,
        enteFile: File,
        localFile: globalThis.File,
        config?: MLSyncConfig
    ) {
        return mlService.syncLocalFile(token, enteFile, localFile, config);
    }

    public async sync(token: string) {
        return mlService.sync(token);
    }
}

expose(DedicatedMLWorker, self);
