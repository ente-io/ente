import ElectronAPIs from "@ente/shared/electron";

export interface ProxiedLimitedElectronAPIs {
    convertToJPEG: (
        inputFileData: Uint8Array,
        filename: string,
    ) => Promise<Uint8Array>;
    logToDisk: (message: string) => void;
}

export class WorkerSafeElectronClient implements ProxiedLimitedElectronAPIs {
    async convertToJPEG(
        inputFileData: Uint8Array,
        filename: string,
    ): Promise<Uint8Array> {
        return await ElectronAPIs.convertToJPEG(inputFileData, filename);
    }
    logToDisk(message: string) {
        return ElectronAPIs.logToDisk(message);
    }
}
