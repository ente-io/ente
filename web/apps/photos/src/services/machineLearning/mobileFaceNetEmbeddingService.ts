import { workerBridge } from "@/next/worker/worker-bridge";
import {
    FaceEmbedding,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    Versioned,
} from "types/machineLearning";

export const mobileFaceNetFaceSize = 112;

class MobileFaceNetEmbeddingService implements FaceEmbeddingService {
    public method: Versioned<FaceEmbeddingMethod>;
    public faceSize: number;

    public constructor() {
        this.method = {
            value: "MobileFaceNet",
            version: 2,
        };
        this.faceSize = mobileFaceNetFaceSize;
    }

    public async getFaceEmbeddings(
        faceData: Float32Array,
    ): Promise<Array<FaceEmbedding>> {
        const outputData = await workerBridge.faceEmbedding(faceData);

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
    }
}

export default new MobileFaceNetEmbeddingService();
