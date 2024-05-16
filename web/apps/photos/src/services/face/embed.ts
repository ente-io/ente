import { workerBridge } from "@/next/worker/worker-bridge";
import { FaceEmbedding } from "services/face/types";

export const mobileFaceNetFaceSize = 112;

/**
 * Compute embeddings for the given {@link faceData}.
 *
 * The model used is MobileFaceNet, running in an ONNX runtime.
 */
export const faceEmbeddings = async (
    faceData: Float32Array,
): Promise<Array<FaceEmbedding>> => {
    const outputData = await workerBridge.faceEmbeddings(faceData);

    const embeddingSize = 192;
    const embeddings = new Array<FaceEmbedding>(
        outputData.length / embeddingSize,
    );
    for (let i = 0; i < embeddings.length; i++) {
        embeddings[i] = new Float32Array(
            outputData.slice(i * embeddingSize, (i + 1) * embeddingSize),
        );
    }
    return embeddings;
};
