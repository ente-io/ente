import { Embedding } from "types/embedding";

export const getLatestVersionEmbeddings = (embeddings: Embedding[]) => {
    const latestVersionEntities = new Map<number, Embedding>();
    embeddings.forEach((embedding) => {
        if (!embedding?.fileID) {
            return;
        }
        const existingEmbeddings = latestVersionEntities.get(embedding.fileID);
        if (
            !existingEmbeddings ||
            existingEmbeddings.updatedAt < embedding.updatedAt
        ) {
            latestVersionEntities.set(embedding.fileID, embedding);
        }
    });
    return Array.from(latestVersionEntities.values());
};
