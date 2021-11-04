import { MLSyncResult } from 'utils/machineLearning/types';
import * as tf from '@tensorflow/tfjs';
import { setWasmPaths } from '@tensorflow/tfjs-backend-wasm';
import TFJSFaceDetectionService from './tfjsFaceDetectionService';

class MachineLearningService {
    private faceDetectionService: TFJSFaceDetectionService;

    public constructor() {
        this.faceDetectionService = new TFJSFaceDetectionService();
    }

    public async init() {
        await tf.ready();
        setWasmPaths('/js/tfjs/');
        await this.faceDetectionService.init();
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
