import { EnteFile } from 'types/file';
import {
    putEmbedding,
    getLatestEmbeddings,
    getLocalEmbeddings,
} from './embeddingService';
import { getAllLocalFiles, getLocalFiles } from './fileService';
import { ElectronAPIs } from 'types/electron';
import downloadManager from './downloadManager';
import { getToken } from 'utils/common/key';
import { Embedding, Model } from 'types/embedding';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { logError } from 'utils/sentry';
import { addLogLine } from 'utils/logging';
import { CustomError } from 'utils/error';
import { LS_KEYS, getData } from 'utils/storage/localStorage';
import { getPersonalFiles } from 'utils/file';
import isElectron from 'is-electron';
import { Events, eventBus } from './events';
import PQueue from 'p-queue';
import { FILE_TYPE } from 'constants/file';

const CLIP_EMBEDDING_LENGTH = 512;

export interface ClipExtractionStatus {
    pending: number;
    indexed: number;
}

class ClipServiceImpl {
    private electronAPIs: ElectronAPIs;
    private embeddingExtractionInProgress: AbortController = null;
    private reRunNeeded = false;
    private clipExtractionStatus: ClipExtractionStatus = {
        pending: 0,
        indexed: 0,
    };
    private onUpdateHandler: (status: ClipExtractionStatus) => void = null;
    private liveEmbeddingExtractionQueue: PQueue;
    private onFileUploadedHandler: (arg: {
        enteFile: EnteFile;
        localFile: globalThis.File;
    }) => void = null;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
        this.liveEmbeddingExtractionQueue = new PQueue({
            concurrency: 1,
        });
    }

    setupOnFileUploadListener = async () => {
        try {
            const isClipSupported = await this.isClipSupported();
            if (!isClipSupported) {
                return;
            }
            if (this.onFileUploadedHandler) {
                addLogLine('file upload listener already setup');
                return;
            }
            addLogLine('setting up file upload listener');
            this.onFileUploadedHandler = (args) => {
                this.runLocalFileClipExtraction(args);
            };
            eventBus.on(Events.FILE_UPLOADED, this.onFileUploadedHandler, this);
            addLogLine('setup file upload listener successfully');
        } catch (e) {
            logError(e, 'failed to setup clip service');
        }
    };

    removeOnFileUploadListener = async () => {
        try {
            if (!this.onFileUploadedHandler) {
                addLogLine('file upload listener already removed');
                return;
            }
            addLogLine('removing file upload listener');
            eventBus.removeListener(
                Events.FILE_UPLOADED,
                this.onFileUploadedHandler,
                this
            );
            this.onFileUploadedHandler = null;
            addLogLine('removed file upload listener successfully');
        } catch (e) {
            logError(e, 'failed to remove clip service');
        }
    };

    updateIndexStatus = async () => {
        try {
            addLogLine('loading local clip index status');
            this.clipExtractionStatus = await getClipExtractionStatus();
            this.onUpdateHandler(this.clipExtractionStatus);
            addLogLine('loaded local clip index status');
        } catch (e) {
            logError(e, 'failed to load local clip index status');
        }
    };

    isClipSupported = async () => {
        if (!isElectron()) {
            return false;
        }
        const platform = await this.electronAPIs.getPlatform();
        return platform !== 'windows';
    };

    setOnUpdateHandler = (handler: (status: ClipExtractionStatus) => void) => {
        this.onUpdateHandler = handler;
        handler(this.clipExtractionStatus);
    };

    scheduleImageEmbeddingExtraction = async () => {
        try {
            if (this.embeddingExtractionInProgress) {
                addLogLine(
                    'clip embedding extraction already in progress, scheduling re-run'
                );
                this.reRunNeeded = true;
                return;
            } else {
                addLogLine(
                    'clip embedding extraction not in progress, starting clip embedding extraction'
                );
            }
            const canceller = new AbortController();
            this.embeddingExtractionInProgress = canceller;
            try {
                await this.runClipEmbeddingExtraction(canceller);
            } finally {
                this.embeddingExtractionInProgress = null;
                if (!canceller.signal.aborted && this.reRunNeeded) {
                    this.reRunNeeded = false;
                    addLogLine('re-running clip embedding extraction');
                    setTimeout(
                        () => this.scheduleImageEmbeddingExtraction(),
                        0
                    );
                }
            }
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'failed to schedule clip embedding extraction');
            }
        }
    };

    getTextEmbedding = async (text: string): Promise<Float32Array> => {
        try {
            return this.electronAPIs.computeTextEmbedding(text);
        } catch (e) {
            logError(e, 'failed to compute text embedding');
            throw e;
        }
    };

    private runClipEmbeddingExtraction = async (canceller: AbortController) => {
        try {
            const user = getData(LS_KEYS.USER);
            if (!user) {
                return;
            }
            const localFiles = getPersonalFiles(await getAllLocalFiles(), user);
            const existingEmbeddings = await getLatestClipImageEmbeddings();
            const pendingFiles = await getNonClipEmbeddingExtractedFiles(
                localFiles,
                existingEmbeddings
            );
            this.updateClipEmbeddingExtractionStatus({
                indexed: existingEmbeddings.length,
                pending: pendingFiles.length,
            });
            if (pendingFiles.length === 0) {
                addLogLine('no clip embedding extraction needed, all done');
                return;
            }
            addLogLine(
                `starting clip embedding extraction for ${pendingFiles.length} files`
            );
            for (const file of pendingFiles) {
                try {
                    addLogLine(
                        `extracting clip embedding for file: ${file.metadata.title} fileID: ${file.id}`
                    );
                    if (canceller.signal.aborted) {
                        throw Error(CustomError.REQUEST_CANCELLED);
                    }
                    const embeddingData =
                        await this.extractFileClipImageEmbedding(file);
                    addLogLine(
                        `successfully extracted clip embedding for file: ${file.metadata.title} fileID: ${file.id} embedding length: ${embeddingData?.length}`
                    );
                    await this.encryptAndUploadEmbedding(file, embeddingData);
                    this.onSuccessStatusUpdater();
                    addLogLine(
                        `successfully put clip embedding to server for file: ${file.metadata.title} fileID: ${file.id}`
                    );
                } catch (e) {
                    if (e.message !== CustomError.REQUEST_CANCELLED) {
                        logError(
                            e,
                            'failed to extract clip embedding for file'
                        );
                    }
                }
            }
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'failed to extract clip embedding');
            }
            throw e;
        }
    };

    private async runLocalFileClipExtraction(arg: {
        enteFile: EnteFile;
        localFile: globalThis.File;
    }) {
        const { enteFile, localFile } = arg;
        addLogLine(
            `clip embedding extraction onFileUploadedHandler file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
            enteFile.id
        );
        if (enteFile.metadata.fileType === FILE_TYPE.VIDEO) {
            addLogLine(
                `skipping video file for clip embedding extraction file: ${enteFile.metadata.title} fileID: ${enteFile.id}`
            );
            return;
        }
        try {
            await this.liveEmbeddingExtractionQueue.add(async () => {
                const embedding = await this.extractLocalFileClipImageEmbedding(
                    localFile
                );
                await this.encryptAndUploadEmbedding(enteFile, embedding);
            });
            addLogLine(
                `successfully extracted clip embedding for file: ${enteFile.metadata.title} fileID: ${enteFile.id}`
            );
        } catch (e) {
            logError(e, 'Failed in ML onFileUploadedHandler');
        }
    }

    private extractLocalFileClipImageEmbedding = async (localFile: File) => {
        const file = await localFile
            .arrayBuffer()
            .then((buffer) => new Uint8Array(buffer));
        const embedding = await this.electronAPIs.computeImageEmbedding(file);
        return embedding;
    };

    private encryptAndUploadEmbedding = async (
        file: EnteFile,
        embeddingData: Float32Array
    ) => {
        if (embeddingData?.length !== CLIP_EMBEDDING_LENGTH) {
            throw Error(
                `invalid length embedding data length: ${embeddingData?.length}`
            );
        }
        const comlinkCryptoWorker = await ComlinkCryptoWorker.getInstance();
        const { file: encryptedEmbeddingData } =
            await comlinkCryptoWorker.encryptEmbedding(embeddingData, file.key);
        addLogLine(
            `putting clip embedding to server for file: ${file.metadata.title} fileID: ${file.id}`
        );
        await putEmbedding({
            fileID: file.id,
            encryptedEmbedding: encryptedEmbeddingData.encryptedData,
            decryptionHeader: encryptedEmbeddingData.decryptionHeader,
            model: Model.GGML_CLIP,
        });
    };

    updateClipEmbeddingExtractionStatus = (status: ClipExtractionStatus) => {
        this.clipExtractionStatus = status;
        if (this.onUpdateHandler) {
            this.onUpdateHandler(status);
        }
    };

    private extractFileClipImageEmbedding = async (file: EnteFile) => {
        const token = getToken();
        if (!token) {
            return;
        }
        let thumb: Uint8Array;
        const thumbURL = await downloadManager.getCachedThumbnail(file);
        if (thumbURL) {
            thumb = await fetch(thumbURL)
                .then((response) => response.arrayBuffer())
                .then((buffer) => new Uint8Array(buffer));
        } else {
            thumb = await downloadManager.downloadThumb(token, file);
        }
        const embedding = await this.electronAPIs.computeImageEmbedding(thumb);
        return embedding;
    };

    private onSuccessStatusUpdater = () => {
        this.updateClipEmbeddingExtractionStatus({
            pending: this.clipExtractionStatus.pending - 1,
            indexed: this.clipExtractionStatus.indexed + 1,
        });
    };
}

export const ClipService = new ClipServiceImpl();

const getNonClipEmbeddingExtractedFiles = async (
    files: EnteFile[],
    existingEmbeddings: Embedding[]
) => {
    const existingEmbeddingFileIds = new Set<number>();
    existingEmbeddings.forEach((embedding) =>
        existingEmbeddingFileIds.add(embedding.fileID)
    );
    const idSet = new Set<number>();
    return files.filter((file) => {
        if (idSet.has(file.id)) {
            return false;
        }
        if (existingEmbeddingFileIds.has(file.id)) {
            return false;
        }
        idSet.add(file.id);
        return true;
    });
};

export const getLocalClipImageEmbeddings = async () => {
    const allEmbeddings = await getLocalEmbeddings();
    return allEmbeddings.filter(
        (embedding) => embedding.model === Model.GGML_CLIP
    );
};

export const computeClipMatchScore = async (
    imageEmbedding: Float32Array,
    textEmbedding: Float32Array
) => {
    if (imageEmbedding.length !== textEmbedding.length) {
        throw Error('imageEmbedding and textEmbedding length mismatch');
    }
    let score = 0;
    let imageNormalization = 0;
    let textNormalization = 0;

    for (let index = 0; index < imageEmbedding.length; index++) {
        imageNormalization += imageEmbedding[index] * imageEmbedding[index];
        textNormalization += textEmbedding[index] * textEmbedding[index];
    }
    for (let index = 0; index < imageEmbedding.length; index++) {
        imageEmbedding[index] =
            imageEmbedding[index] / Math.sqrt(imageNormalization);
        textEmbedding[index] =
            textEmbedding[index] / Math.sqrt(textNormalization);
    }
    for (let index = 0; index < imageEmbedding.length; index++) {
        score += imageEmbedding[index] * textEmbedding[index];
    }
    return score;
};

const getLatestClipImageEmbeddings = async () => {
    const allEmbeddings = await getLatestEmbeddings();
    return allEmbeddings.filter(
        (embedding) => embedding.model === Model.GGML_CLIP
    );
};

const getClipExtractionStatus = async (): Promise<ClipExtractionStatus> => {
    const user = getData(LS_KEYS.USER);
    if (!user) {
        return;
    }
    const allEmbeddings = await getLocalClipImageEmbeddings();
    const localFiles = getPersonalFiles(await getLocalFiles(), user);
    const pendingFiles = await getNonClipEmbeddingExtractedFiles(
        localFiles,
        allEmbeddings
    );
    return {
        indexed: allEmbeddings.length,
        pending: pendingFiles.length,
    };
};
