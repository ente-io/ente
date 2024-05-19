import { APPS } from "@ente/shared/apps/constants";
import { expose } from "comlink";
import downloadManager from "services/download";
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
        await downloadManager.init(APPS.PHOTOS, { token });
        return mlService.sync(token, userID);
    }
}

expose(DedicatedMLWorker, self);
