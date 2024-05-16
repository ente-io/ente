import log from "@/next/log";
import { expose } from "comlink";
import { MachineLearningWorker } from "services/face/types";
import mlService from "services/machineLearning/machineLearningService";
import { EnteFile } from "types/file";

export class DedicatedMLWorker implements MachineLearningWorker {
    constructor() {
        log.info("DedicatedMLWorker constructor called");
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
