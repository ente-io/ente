import {
    MOBILEFACENET_EMBEDDING_SIZE,
    MOBILEFACENET_FACE_SIZE,
} from "constants/mlConfig";
import {
    FaceEmbedding,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    Versioned,
} from "types/machineLearning";

// TODO(MR): onnx-yolo
// import * as ort from "onnxruntime-web";
// import { env } from "onnxruntime-web";
const ort: any = {};

// TODO(MR): onnx-yolo
// env.wasm.wasmPaths = "/js/onnx/";
class MobileFaceNetEmbeddingService implements FaceEmbeddingService {
    // TODO(MR): onnx-yolo
    // private onnxInferenceSession?: ort.InferenceSession;
    private onnxInferenceSession?: any;
    public method: Versioned<FaceEmbeddingMethod>;
    public faceSize: number;

    public constructor() {
        this.method = {
            value: "MobileFaceNet",
            version: 2,
        };
        this.faceSize = MOBILEFACENET_FACE_SIZE;
        // TODO: set timeout
    }

    private async initOnnx() {
        console.log("start ort mobilefacenet");
        this.onnxInferenceSession = await ort.InferenceSession.create(
            "/models/mobilefacenet/mobilefacenet_opset15.onnx",
        );
        const faceBatchSize = 1;
        const data = new Float32Array(
            faceBatchSize * 3 * this.faceSize * this.faceSize,
        );
        const inputTensor = new ort.Tensor("float32", data, [
            faceBatchSize,
            this.faceSize,
            this.faceSize,
            3,
        ]);
        // TODO(MR): onnx-yolo
        // const feeds: Record<string, ort.Tensor> = {};
        const feeds: Record<string, any> = {};
        const name = this.onnxInferenceSession.inputNames[0];
        feeds[name] = inputTensor;
        await this.onnxInferenceSession.run(feeds);
        console.log("start end mobilefacenet");
    }

    private async getOnnxInferenceSession() {
        if (!this.onnxInferenceSession) {
            await this.initOnnx();
        }
        return this.onnxInferenceSession;
    }

    public async getFaceEmbeddings(
        faceData: Float32Array,
    ): Promise<Array<FaceEmbedding>> {
        const inputTensor = new ort.Tensor("float32", faceData, [
            Math.round(faceData.length / (this.faceSize * this.faceSize * 3)),
            this.faceSize,
            this.faceSize,
            3,
        ]);
        // TODO(MR): onnx-yolo
        // const feeds: Record<string, ort.Tensor> = {};
        const feeds: Record<string, any> = {};
        feeds["img_inputs"] = inputTensor;
        const inferenceSession = await this.getOnnxInferenceSession();
        // TODO(MR): onnx-yolo
        // const runout: ort.InferenceSession.OnnxValueMapType =
        const runout: any = await inferenceSession.run(feeds);
        // const test = runout.embeddings;
        // const test2 = test.cpuData;
        const outputData = runout.embeddings["cpuData"] as Float32Array;
        const embeddings = new Array<FaceEmbedding>(
            outputData.length / MOBILEFACENET_EMBEDDING_SIZE,
        );
        for (let i = 0; i < embeddings.length; i++) {
            embeddings[i] = new Float32Array(
                outputData.slice(
                    i * MOBILEFACENET_EMBEDDING_SIZE,
                    (i + 1) * MOBILEFACENET_EMBEDDING_SIZE,
                ),
            );
        }
        return embeddings;
    }

    public async dispose() {
        const inferenceSession = await this.getOnnxInferenceSession();
        inferenceSession?.release();
        this.onnxInferenceSession = undefined;
    }
}

export default new MobileFaceNetEmbeddingService();
