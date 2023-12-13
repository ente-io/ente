import * as Comlink from 'comlink';
import { LimitedCache } from '@ente/shared/storage/cacheStorage/types';
import {
    ProxiedWorkerLimitedCache,
    WorkerSafeElectronClient,
} from './worker/client';
import { wrap } from 'comlink';
import { deserializeToResponse, serializeResponse } from './worker/utils/proxy';
import { runningInWorker } from '@ente/shared/platform';
import { ElectronAPIsType } from './types';

export interface LimitedElectronAPIs
    extends Pick<
        ElectronAPIsType,
        | 'openDiskCache'
        | 'deleteDiskCache'
        | 'getSentryUserID'
        | 'convertToJPEG'
    > {}

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
    async openDiskCache(cacheName: string, cacheLimitInBytes?: number) {
        await this.ready;
        const cache = await this.proxiedElectron.openDiskCache(
            cacheName,
            cacheLimitInBytes
        );
        return {
            match: transformMatch(cache.match.bind(cache)),
            put: transformPut(cache.put.bind(cache)),
            delete: cache.delete.bind(cache),
        };
    }

    async deleteDiskCache(cacheName: string) {
        await this.ready;
        return await this.proxiedElectron.deleteDiskCache(cacheName);
    }

    async getSentryUserID() {
        await this.ready;
        return this.proxiedElectron.getSentryUserID();
    }
    async convertToJPEG(
        inputFileData: Uint8Array,
        filename: string
    ): Promise<Uint8Array> {
        await this.ready;
        return this.proxiedElectron.convertToJPEG(inputFileData, filename);
    }
}

export const WorkerSafeElectronService = new WorkerSafeElectronServiceImpl();

function transformMatch(
    fn: ProxiedWorkerLimitedCache['match']
): LimitedCache['match'] {
    return async (key: string, options) => {
        return deserializeToResponse(await fn(key, options));
    };
}

function transformPut(
    fn: ProxiedWorkerLimitedCache['put']
): LimitedCache['put'] {
    return async (key: string, data: Response) => {
        fn(key, await serializeResponse(data));
    };
}
