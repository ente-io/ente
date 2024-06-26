import { FILE_TYPE } from "@/media/file-type";
import { getAllLocalFiles, getLocalFiles } from "@/new/photos/services/files";
import { EnteFile } from "@/new/photos/types/file";
import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { CustomError } from "@ente/shared/error";
import { Events, eventBus } from "@ente/shared/events";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import isElectron from "is-electron";
import PQueue from "p-queue";
import { Embedding } from "types/embedding";
import { getPersonalFiles } from "utils/file";
import downloadManager from "./download";
import { localCLIPEmbeddings, putEmbedding } from "./embeddingService";

/** Status of CLIP indexing on the images in the user's local library. */
export interface CLIPIndexingStatus {
    /** Number of items pending indexing. */
    pending: number;
    /** Number of items that have already been indexed. */
    indexed: number;
}

/**
 * Use a CLIP based neural network for natural language search.
 *
 * [Note: CLIP based magic search]
 *
 * CLIP (Contrastive Language-Image Pretraining) is a neural network trained on
 * (image, text) pairs. It can be thought of as two separate (but jointly
 * trained) encoders - one for images, and one for text - that both map to the
 * same embedding space.
 *
 * We use this for natural language search within the app (aka "magic search"):
 *
 * 1. Pre-compute an embedding for each image.
 *
 * 2. When the user searches, compute an embedding for the search term.
 *
 * 3. Use cosine similarity to find the find the image (embedding) closest to
 *    the text (embedding).
 *
 * More details are in our [blog
 * post](https://ente.io/blog/image-search-with-clip-ggml/) that describes the
 * initial launch of this feature using the GGML runtime.
 *
 * Since the initial launch, we've switched over to another runtime,
 * [ONNX](https://onnxruntime.ai).
 *
 * Note that we don't train the neural network - we only use one of the publicly
 * available pre-trained neural networks for inference. These neural networks
 * are wholly defined by their connectivity and weights. ONNX, our ML runtimes,
 * loads these weights and instantiates a running network that we can use to
 * compute the embeddings.
 *
 * Theoretically, the same CLIP model can be loaded by different frameworks /
 * runtimes, but in practice each runtime has its own preferred format, and
 * there are also quantization tradeoffs. So there is a specific model (a binary
 * encoding of weights) tied to our current runtime that we use.
 *
 * To ensure that the embeddings, for the most part, can be shared, whenever
 * possible we try to ensure that all the preprocessing steps, and the model
 * itself, is the same across clients - web and mobile.
 */
class CLIPService {
    private embeddingExtractionInProgress: AbortController | null = null;
    private reRunNeeded = false;
    private indexingStatus: CLIPIndexingStatus = {
        pending: 0,
        indexed: 0,
    };
    private onUpdateHandler: ((status: CLIPIndexingStatus) => void) | undefined;
    private liveEmbeddingExtractionQueue: PQueue;
    private onFileUploadedHandler:
        | ((arg: { enteFile: EnteFile; localFile: globalThis.File }) => void)
        | null = null;

    constructor() {
        this.liveEmbeddingExtractionQueue = new PQueue({
            concurrency: 1,
        });
    }

    isPlatformSupported = () => {
        return isElectron();
    };

    async logout() {
        if (this.embeddingExtractionInProgress) {
            this.embeddingExtractionInProgress.abort();
        }
        if (this.onFileUploadedHandler) {
            await this.removeOnFileUploadListener();
        }
    }

    setupOnFileUploadListener = async () => {
        try {
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
        if (
            this.indexingStatus.pending === 0 &&
            this.indexingStatus.indexed === 0
        ) {
            this.indexingStatus = await initialIndexingStatus();
        }
        return this.indexingStatus;
    };

    /**
     * Set the {@link handler} to invoke whenever our indexing status changes.
     */
    setOnUpdateHandler = (handler?: (status: CLIPIndexingStatus) => void) => {
        this.onUpdateHandler = handler;
    };

    scheduleImageEmbeddingExtraction = async () => {
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
                await this.runClipEmbeddingExtraction(canceller);
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

    getTextEmbeddingIfAvailable = async (text: string) => {
        return ensureElectron().computeCLIPTextEmbeddingIfAvailable(text);
    };

    private runClipEmbeddingExtraction = async (canceller: AbortController) => {
        try {
            const user = getData(LS_KEYS.USER);
            if (!user) {
                return;
            }
            const localFiles = getPersonalFiles(await getAllLocalFiles(), user);
            const existingEmbeddings = await localCLIPEmbeddings();
            const pendingFiles = await getNonClipEmbeddingExtractedFiles(
                localFiles,
                existingEmbeddings,
            );
            this.updateIndexingStatus({
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
                        await this.extractFileClipImageEmbedding(file);
                    log.info(
                        `successfully extracted clip embedding for file: ${file.metadata.title} fileID: ${file.id} embedding length: ${embeddingData?.length}`,
                    );
                    await this.encryptAndUploadEmbedding(file, embeddingData);
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

    private async runLocalFileClipExtraction(arg: {
        enteFile: EnteFile;
        localFile: globalThis.File;
    }) {
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
                const embedding =
                    await this.extractLocalFileClipImageEmbedding(localFile);
                await this.encryptAndUploadEmbedding(enteFile, embedding);
            });
            log.info(
                `successfully extracted clip embedding for file: ${enteFile.metadata.title} fileID: ${enteFile.id}`,
            );
        } catch (e) {
            log.error("Failed in ML onFileUploadedHandler", e);
        }
    }

    private extractLocalFileClipImageEmbedding = async (localFile: File) => {
        const file = await localFile
            .arrayBuffer()
            .then((buffer) => new Uint8Array(buffer));
        return await ensureElectron().computeCLIPImageEmbedding(file);
    };

    private encryptAndUploadEmbedding = async (
        file: EnteFile,
        embeddingData: Float32Array,
    ) => {
        if (embeddingData?.length !== 512) {
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
            model: "onnx-clip",
        });
    };

    private updateIndexingStatus = (status: CLIPIndexingStatus) => {
        this.indexingStatus = status;
        const handler = this.onUpdateHandler;
        if (handler) handler(status);
    };

    private extractFileClipImageEmbedding = async (file: EnteFile) => {
        const thumb = await downloadManager.getThumbnail(file);
        const embedding =
            await ensureElectron().computeCLIPImageEmbedding(thumb);
        return embedding;
    };

    private onSuccessStatusUpdater = () => {
        this.updateIndexingStatus({
            pending: this.indexingStatus.pending - 1,
            indexed: this.indexingStatus.indexed + 1,
        });
    };
}

export const clipService = new CLIPService();

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

const initialIndexingStatus = async (): Promise<CLIPIndexingStatus> => {
    const user = getData(LS_KEYS.USER);
    if (!user) throw new Error("Orphan CLIP indexing without a login");
    const allEmbeddings = await localCLIPEmbeddings();
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
