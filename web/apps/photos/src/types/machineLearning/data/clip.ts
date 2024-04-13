export interface ClipEmbedding {
    embedding: Float32Array;
    model: "ggml-clip" | "onnx-clip";
}
