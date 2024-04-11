/**
 * The embeddings models that we support.
 *
 * This is an exhaustive set of values we pass when PUT-ting encrypted
 * embeddings on the server. However, we should be prepared to receive an
 * {@link EncryptedEmbedding} with a model value distinct from one of these.
 */
export type EmbeddingModel = "onnx-clip" | "file-ml-clip-face";

export interface EncryptedEmbedding {
    fileID: number;
    /** @see {@link EmbeddingModel} */
    model: string;
    encryptedEmbedding: string;
    decryptionHeader: string;
    updatedAt: number;
}

export interface Embedding
    extends Omit<
        EncryptedEmbedding,
        "encryptedEmbedding" | "decryptionHeader"
    > {
    embedding?: Float32Array;
}

export interface GetEmbeddingDiffResponse {
    diff: EncryptedEmbedding[];
}

export interface PutEmbeddingRequest {
    fileID: number;
    model: EmbeddingModel;
    encryptedEmbedding: string;
    decryptionHeader: string;
}
