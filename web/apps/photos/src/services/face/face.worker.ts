import { expose } from "comlink";
import mlService from "services/machineLearning/machineLearningService";
import { EnteFile } from "types/file";

export class DedicatedMLWorker {
    public async closeLocalSyncContext() {
        return mlService.closeLocalSyncContext();
    }

    public async syncLocalFile(
        token: string,
        userID: number,
        enteFile: EnteFile,
        localFile: globalThis.File,
    ) {
        mlService.syncLocalFile(token, userID, enteFile, localFile);
    }

    public async sync(token: string, userID: number) {
        return mlService.sync(token, userID);
    }

    public async regenerateFaceCrop(token: string, faceID: string) {
        return mlService.regenerateFaceCrop(faceID);
    }
}

expose(DedicatedMLWorker, self);
