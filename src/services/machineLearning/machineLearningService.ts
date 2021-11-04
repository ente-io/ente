import { MLSyncResult } from 'utils/machineLearning/types';
import * as tf from '@tensorflow/tfjs';
import { setWasmPaths } from '@tensorflow/tfjs-backend-wasm';
import TFJSFaceDetectionService from './tfjsFaceDetectionService';
import TFJSFaceEmbeddingService from './tfjsFaceEmbeddingService';

class MachineLearningService {
    private faceDetectionService: TFJSFaceDetectionService;
    private faceEmbeddingService: TFJSFaceEmbeddingService;

    public constructor() {
        this.faceDetectionService = new TFJSFaceDetectionService();
        this.faceEmbeddingService = new TFJSFaceEmbeddingService();
    }

    public async init() {
        await tf.ready();
        setWasmPaths('/js/tfjs/');
        await this.faceDetectionService.init();
        await this.faceEmbeddingService.init();
    }

    public async sync(token: string): Promise<MLSyncResult> {
        if (!token) {
            console.warn('No token provided');
        }
        return {
            allFaces: [],
        };
    }
}

export default MachineLearningService;
