import type { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { putEmbedding } from "services/embeddingService";
import type { FaceIndex } from "./types";

export const putFaceIndex = async (
    enteFile: EnteFile,
    faceIndex: FaceIndex,
) => {
    log.debug(() => ({
        t: "Uploading faceEmbedding",
        d: JSON.stringify(faceIndex),
    }));

    const comlinkCryptoWorker = await ComlinkCryptoWorker.getInstance();
    const { file: encryptedEmbeddingData } =
        await comlinkCryptoWorker.encryptMetadata(faceIndex, enteFile.key);
    await putEmbedding({
        fileID: enteFile.id,
        encryptedEmbedding: encryptedEmbeddingData.encryptedData,
        decryptionHeader: encryptedEmbeddingData.decryptionHeader,
        model: "file-ml-clip-face",
    });
};
