import { EnteFile } from 'types/file';
import { putEmbedding, getLocalEmbeddings } from './embeddingService';
import { getLocalFiles } from './fileService';
import { ElectronAPIs } from 'types/electron';
import downloadManager from './downloadManager';
import { getToken } from 'utils/common/key';
import { Embedding, Model } from 'types/embedding';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { logError } from 'utils/sentry';
import { addLogLine } from 'utils/logging';

class ClipServiceImpl {
    private electronAPIs: ElectronAPIs;
    private embeddingExtractionInProgress = false;
    private reRunNeeded = false;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
    }

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
            this.embeddingExtractionInProgress = true;
            try {
                await this.runClipEmbeddingExtraction();
            } finally {
                this.embeddingExtractionInProgress = false;
                if (this.reRunNeeded) {
                    this.reRunNeeded = false;
                    addLogLine('re-running clip embedding extraction');
                    setTimeout(
                        () => this.scheduleImageEmbeddingExtraction(),
                        0
                    );
                }
            }
        } catch (e) {
            logError(e, 'failed to schedule clip embedding extraction');
        }
    };

    private runClipEmbeddingExtraction = async () => {
        try {
            const localFiles = await getLocalFiles();
            const existingEmbeddings = await getLocalEmbeddings();
            const pendingFiles = await getNonClipEmbeddingExtractedFiles(
                localFiles,
                existingEmbeddings
            );
            if (pendingFiles.length === 0) {
                return;
            }
            for (const file of pendingFiles) {
                try {
                    const embedding = await this.extractClipImageEmbedding(
                        file
                    );
                    const comlinkCryptoWorker =
                        await ComlinkCryptoWorker.getInstance();
                    const { file: encryptedEmbedding } =
                        await comlinkCryptoWorker.encryptEmbedding(
                            embedding,
                            file.key
                        );
                    await putEmbedding({
                        fileID: file.id,
                        encryptedEmbedding: encryptedEmbedding.encryptedData,
                        decryptionHeader: encryptedEmbedding.decryptionHeader,
                        model: Model.GGML_CLIP,
                    });
                } catch (e) {
                    logError(e, 'failed to extract clip embedding for file');
                }
            }
        } catch (e) {
            logError(e, 'failed to extract clip embedding');
        }
    };

    private extractClipImageEmbedding = async (file: EnteFile) => {
        const token = getToken();
        if (!token) {
            return;
        }
        const thumb = await downloadManager.downloadThumb(token, file);
        const embedding = await this.electronAPIs.computeImageEmbedding(thumb);
        return embedding;
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
    return files.filter((file) => !existingEmbeddingFileIds.has(file.id));
};
