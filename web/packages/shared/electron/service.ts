import { runningInWorker } from "@ente/shared/platform";
import * as Comlink from "comlink";
import { wrap } from "comlink";
import { ElectronAPIsType } from "./types";
import { WorkerSafeElectronClient } from "./worker/client";

export interface LimitedElectronAPIs
    extends Pick<ElectronAPIsType, "convertToJPEG" | "logToDisk"> {}

class WorkerSafeElectronServiceImpl implements LimitedElectronAPIs {
    proxiedElectron:
        | Comlink.Remote<WorkerSafeElectronClient>
        | WorkerSafeElectronClient;
    ready: Promise<any>;

    constructor() {
        this.ready = this.init();
    }
    private async init() {
        if (runningInWorker()) {
            const workerSafeElectronClient =
                wrap<typeof WorkerSafeElectronClient>(self);

            this.proxiedElectron = await new workerSafeElectronClient();
        } else {
            this.proxiedElectron = new WorkerSafeElectronClient();
        }
    }

    async convertToJPEG(
        inputFileData: Uint8Array,
        filename: string,
    ): Promise<Uint8Array> {
        await this.ready;
        return this.proxiedElectron.convertToJPEG(inputFileData, filename);
    }

    async logToDisk(message: string) {
        await this.ready;
        return this.proxiedElectron.logToDisk(message);
    }
}

export const WorkerSafeElectronService = new WorkerSafeElectronServiceImpl();
