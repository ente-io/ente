import { addLogLine } from "@ente/shared/logging";
import { expose } from "comlink";
import mlService from "services/machineLearning/machineLearningService";
import { EnteFile } from "types/file";
import { MachineLearningWorker } from "types/machineLearning";

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {
        addLogLine("DedicatedMLWorker constructor called");
    }

    public async closeLocalSyncContext() {
        return mlService.closeLocalSyncContext();
    }

    public async syncLocalFile(
        token: string,
        userID: number,
        enteFile: EnteFile,
        localFile: globalThis.File,
    ) {
        return mlService.syncLocalFile(token, userID, enteFile, localFile);
    }

    public async sync(token: string, userID: number) {
        return mlService.sync(token, userID);
    }

    public async regenerateFaceCrop(
        token: string,
        userID: number,
        faceID: string,
    ) {
        return mlService.regenerateFaceCrop(token, userID, faceID);
    }

    public close() {
        self.close();
    }
}

expose(DedicatedMLWorker, self);
