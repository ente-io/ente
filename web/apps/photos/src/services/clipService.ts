import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { CustomError } from "@ente/shared/error";
import { Events, eventBus } from "@ente/shared/events";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import { FILE_TYPE } from "constants/file";
import isElectron from "is-electron";
import PQueue from "p-queue";
import { Embedding, Model } from "types/embedding";
import { EnteFile } from "types/file";
import { getPersonalFiles } from "utils/file";
import downloadManager from "./download";
import { getLocalEmbeddings, putEmbedding } from "./embeddingService";
import { getAllLocalFiles, getLocalFiles } from "./fileService";

const CLIP_EMBEDDING_LENGTH = 512;

export interface ClipExtractionStatus {
    pending: number;
    indexed: number;
}

class ClipServiceImpl {
    private embeddingExtractionInProgress: AbortController | null = null;
    private reRunNeeded = false;
    private clipExtractionStatus: ClipExtractionStatus = {
        pending: 0,
        indexed: 0,
    };
    private onUpdateHandler: ((status: ClipExtractionStatus) => void) | null =
        null;
    private liveEmbeddingExtractionQueue: PQueue;
    private onFileUploadedHandler:
        | ((arg: { enteFile: EnteFile; localFile: globalThis.File }) => void)
        | null = null;
    private unsupportedPlatform = false;

    constructor() {
        this.liveEmbeddingExtractionQueue = new PQueue({
            concurrency: 1,
        });
        eventBus.on(Events.LOGOUT, this.logoutHandler, this);
    }

    isPlatformSupported = () => {
        return isElectron() && !this.unsupportedPlatform;
    };

    private logoutHandler = async () => {
        if (this.embeddingExtractionInProgress) {
            this.embeddingExtractionInProgress.abort();
        }
        if (this.onFileUploadedHandler) {
            await this.removeOnFileUploadListener();
        }
    };

    setupOnFileUploadListener = async () => {
        try {
            if (this.unsupportedPlatform) {
                return;
            }
            if (this.onFileUploadedHandler) {
                log.info("file upload listener already setup");
                return;
            }
            log.info("setting up file upload listener");
            this.onFileUploadedHandler = (args) => {
                this.runLocalFileClipExtraction(args);
            };
            eventBus.on(Events.FILE_UPLOADED, this.onFileUploadedHandler, this);
            log.info("setup file upload listener successfully");
        } catch (e) {
            log.error("failed to setup clip service", e);
        }
    };

    removeOnFileUploadListener = async () => {
        try {
            if (!this.onFileUploadedHandler) {
                log.info("file upload listener already removed");
                return;
            }
            log.info("removing file upload listener");
            eventBus.removeListener(
                Events.FILE_UPLOADED,
                this.onFileUploadedHandler,
                this,
            );
            this.onFileUploadedHandler = null;
            log.info("removed file upload listener successfully");
        } catch (e) {
            log.error("failed to remove clip service", e);
        }
    };

    getIndexingStatus = async () => {
        try {
            if (
                !this.clipExtractionStatus ||
                (this.clipExtractionStatus.pending === 0 &&
                    this.clipExtractionStatus.indexed === 0)
            ) {
                this.clipExtractionStatus = await getClipExtractionStatus();
            }
            return this.clipExtractionStatus;
        } catch (e) {
            log.error("failed to get clip indexing status", e);
        }
    };

    setOnUpdateHandler = (handler: (status: ClipExtractionStatus) => void) => {
        this.onUpdateHandler = handler;
        handler(this.clipExtractionStatus);
    };

    scheduleImageEmbeddingExtraction = async (
        model: Model = Model.ONNX_CLIP,
    ) => {
        try {
            if (this.embeddingExtractionInProgress) {
                log.info(
                    "clip embedding extraction already in progress, scheduling re-run",
                );
                this.reRunNeeded = true;
                return;
            } else {
                log.info(
                    "clip embedding extraction not in progress, starting clip embedding extraction",
                );
            }
            const canceller = new AbortController();
            this.embeddingExtractionInProgress = canceller;
            try {
                await this.runClipEmbeddingExtraction(canceller, model);
            } finally {
                this.embeddingExtractionInProgress = null;
                if (!canceller.signal.aborted && this.reRunNeeded) {
                    this.reRunNeeded = false;
                    log.info("re-running clip embedding extraction");
                    setTimeout(
                        () => this.scheduleImageEmbeddingExtraction(),
                        0,
                    );
                }
            }
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                log.error("failed to schedule clip embedding extraction", e);
            }
        }
    };

    getTextEmbedding = async (
        text: string,
        model: Model = Model.ONNX_CLIP,
    ): Promise<Float32Array> => {
        try {
            return ensureElectron().computeTextEmbedding(model, text);
        } catch (e) {
            if (e?.message?.includes(CustomError.UNSUPPORTED_PLATFORM)) {
                this.unsupportedPlatform = true;
            }
            log.error("failed to compute text embedding", e);
            throw e;
        }
    };

    private runClipEmbeddingExtraction = async (
        canceller: AbortController,
        model: Model,
    ) => {
        try {
            if (this.unsupportedPlatform) {
                log.info(
                    `skipping clip embedding extraction, platform unsupported`,
                );
                return;
            }
            const user = getData(LS_KEYS.USER);
            if (!user) {
                return;
            }
            const localFiles = getPersonalFiles(await getAllLocalFiles(), user);
            const existingEmbeddings = await getLocalEmbeddings(model);
            const pendingFiles = await getNonClipEmbeddingExtractedFiles(
                localFiles,
                existingEmbeddings,
            );
            this.updateClipEmbeddingExtractionStatus({
                indexed: existingEmbeddings.length,
                pending: pendingFiles.length,
            });
            if (pendingFiles.length === 0) {
                log.info("no clip embedding extraction needed, all done");
                return;
            }
            log.info(
                `starting clip embedding extraction for ${pendingFiles.length} files`,
            );
            for (const file of pendingFiles) {
                try {
                    log.info(
                        `extracting clip embedding for file: ${file.metadata.title} fileID: ${file.id}`,
                    );
                    if (canceller.signal.aborted) {
                        throw Error(CustomError.REQUEST_CANCELLED);
                    }
                    const embeddingData =
                        await this.extractFileClipImageEmbedding(model, file);
                    log.info(
                        `successfully extracted clip embedding for file: ${file.metadata.title} fileID: ${file.id} embedding length: ${embeddingData?.length}`,
                    );
                    await this.encryptAndUploadEmbedding(
                        model,
                        file,
                        embeddingData,
                    );
                    this.onSuccessStatusUpdater();
                    log.info(
                        `successfully put clip embedding to server for file: ${file.metadata.title} fileID: ${file.id}`,
                    );
                } catch (e) {
                    if (e?.message !== CustomError.REQUEST_CANCELLED) {
                        log.error(
                            "failed to extract clip embedding for file",
                            e,
                        );
                    }
                    if (
                        e?.message?.includes(CustomError.UNSUPPORTED_PLATFORM)
                    ) {
                        this.unsupportedPlatform = true;
                    }
                    if (
                        e?.message === CustomError.REQUEST_CANCELLED ||
                        e?.message?.includes(CustomError.UNSUPPORTED_PLATFORM)
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                log.error("failed to extract clip embedding", e);
            }
            throw e;
        }
    };

    private async runLocalFileClipExtraction(
        arg: {
            enteFile: EnteFile;
            localFile: globalThis.File;
        },
        model: Model = Model.ONNX_CLIP,
    ) {
        const { enteFile, localFile } = arg;
        log.info(
            `clip embedding extraction onFileUploadedHandler file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
            enteFile.id,
        );
        if (enteFile.metadata.fileType === FILE_TYPE.VIDEO) {
            log.info(
                `skipping video file for clip embedding extraction file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
            );
            return;
        }
        const extension = enteFile.metadata.title.split(".").pop();
        if (!extension || !["jpg", "jpeg"].includes(extension)) {
            log.info(
                `skipping non jpg file for clip embedding extraction file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
            );
            return;
        }
        log.info(
            `queuing up for local clip embedding extraction for file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
        );
        try {
            await this.liveEmbeddingExtractionQueue.add(async () => {
                const embedding = await this.extractLocalFileClipImageEmbedding(
                    model,
                    localFile,
                );
                await this.encryptAndUploadEmbedding(
                    model,
                    enteFile,
                    embedding,
                );
            });
            log.info(
                `successfully extracted clip embedding for file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
            );
        } catch (e) {
            log.error("Failed in ML onFileUploadedHandler", e);
        }
    }

    private extractLocalFileClipImageEmbedding = async (
        model: Model,
        localFile: File,
    ) => {
        const file = await localFile
            .arrayBuffer()
            .then((buffer) => new Uint8Array(buffer));
        const embedding = await ensureElectron().computeImageEmbedding(
            model,
            file,
        );
        return embedding;
    };

    private encryptAndUploadEmbedding = async (
        model: Model,
        file: EnteFile,
        embeddingData: Float32Array,
    ) => {
        if (embeddingData?.length !== CLIP_EMBEDDING_LENGTH) {
            throw Error(
                `invalid length embedding data length: ${embeddingData?.length}`,
            );
        }
        const comlinkCryptoWorker = await ComlinkCryptoWorker.getInstance();
        const { file: encryptedEmbeddingData } =
            await comlinkCryptoWorker.encryptEmbedding(embeddingData, file.key);
        log.info(
            `putting clip embedding to server for file: ${file.metadata.title} fileID: ${file.id}`,
        );
        await putEmbedding({
            fileID: file.id,
            encryptedEmbedding: encryptedEmbeddingData.encryptedData,
            decryptionHeader: encryptedEmbeddingData.decryptionHeader,
            model,
        });
    };

    updateClipEmbeddingExtractionStatus = (status: ClipExtractionStatus) => {
        this.clipExtractionStatus = status;
        if (this.onUpdateHandler) {
            this.onUpdateHandler(status);
        }
    };

    private extractFileClipImageEmbedding = async (
        model: Model,
        file: EnteFile,
    ) => {
        const thumb = await downloadManager.getThumbnail(file);
        const embedding = await ensureElectron().computeImageEmbedding(
            model,
            thumb,
        );
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
    existingEmbeddings: Embedding[],
) => {
    const existingEmbeddingFileIds = new Set<number>();
    existingEmbeddings.forEach((embedding) =>
        existingEmbeddingFileIds.add(embedding.fileID),
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

export const computeClipMatchScore = async (
    imageEmbedding: Float32Array,
    textEmbedding: Float32Array,
) => {
    if (imageEmbedding.length !== textEmbedding.length) {
        throw Error("imageEmbedding and textEmbedding length mismatch");
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

const getClipExtractionStatus = async (
    model: Model = Model.ONNX_CLIP,
): Promise<ClipExtractionStatus> => {
    const user = getData(LS_KEYS.USER);
    if (!user) {
        return;
    }
    const allEmbeddings = await getLocalEmbeddings(model);
    const localFiles = getPersonalFiles(await getLocalFiles(), user);
    const pendingFiles = await getNonClipEmbeddingExtractedFiles(
        localFiles,
        allEmbeddings,
    );
    return {
        indexed: allEmbeddings.length,
        pending: pendingFiles.length,
    };
};
