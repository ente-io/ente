import { expose } from 'comlink';
import { File } from 'services/fileService';
import mlService from 'services/machineLearning/machineLearningService';
import { MachineLearningWorker } from 'types/machineLearning';

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {}

    public async closeLocalSyncContext() {
        return mlService.closeLocalSyncContext();
    }

    public async syncLocalFile(
        token: string,
        enteFile: File,
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
