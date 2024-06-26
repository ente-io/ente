import type { EmbeddingModel } from "@/new/photos/services/embedding";

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
