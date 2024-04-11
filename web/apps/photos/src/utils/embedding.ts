import { Embedding } from "types/embedding";
import { FileML } from "./machineLearning/mldataMappers";

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

export const getLatestVersionFileEmbeddings = (embeddings: FileML[]) => {
    const latestVersionEntities = new Map<number, FileML>();
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
