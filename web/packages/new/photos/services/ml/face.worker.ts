import downloadManager from "@/new/photos/services/download";
import type { EnteFile } from "@/new/photos/types/file";
import { expose } from "comlink";
import mlService from "./machineLearningService";

export class DedicatedMLWorker {
    public async closeLocalSyncContext() {
        return mlService.closeLocalSyncContext();
    }

    public async syncLocalFile(
        token: string,
        userID: number,
        userAgent: string,
        enteFile: EnteFile,
        localFile: globalThis.File,
    ) {
        return mlService.syncLocalFile(
            token,
            userID,
            userAgent,
            enteFile,
            localFile,
        );
    }

    public async sync(token: string, userID: number, userAgent: string) {
        await downloadManager.init(token);
        return mlService.sync(token, userID, userAgent);
    }
}

expose(DedicatedMLWorker, self);
