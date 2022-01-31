import { expose } from 'comlink';
import { EnteFile } from 'types/file';
import mlService from 'services/machineLearning/machineLearningService';
import { MachineLearningWorker } from 'types/machineLearning';

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {}

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
