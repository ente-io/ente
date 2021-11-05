import { File, getLocalFiles } from 'services/fileService';
import DownloadManager from 'services/downloadManager';

import * as tf from '@tensorflow/tfjs';
import { setWasmPaths } from '@tensorflow/tfjs-backend-wasm';

import TFJSFaceDetectionService from './tfjsFaceDetectionService';
import TFJSFaceEmbeddingService from './tfjsFaceEmbeddingService';
import { FaceWithEmbedding, MLSyncResult } from 'utils/machineLearning/types';

import * as jpeg from 'jpeg-js';
import ClusteringService from './clusteringService';

class MachineLearningService {
    private faceDetectionService: TFJSFaceDetectionService;
    private faceEmbeddingService: TFJSFaceEmbeddingService;
    private clusteringService: ClusteringService;

    private clusterFaceDistance = 0.8;
    private minClusterSize = 4;

    public allFaces: FaceWithEmbedding[];

    public constructor() {
        this.faceDetectionService = new TFJSFaceDetectionService();
        this.faceEmbeddingService = new TFJSFaceEmbeddingService();
        this.clusteringService = new ClusteringService();

        this.allFaces = [];
    }

    public async init(clusterFaceDistance: number, minClusterSize: number) {
        this.clusterFaceDistance = clusterFaceDistance;
        this.minClusterSize = minClusterSize;

        setWasmPaths('/js/tfjs/');
        await tf.ready();

        await this.faceDetectionService.init();
        await this.faceEmbeddingService.init();
    }

    public async sync(token: string): Promise<MLSyncResult> {
        if (!token) {
            throw Error('Token needed by ml service to sync file');
        }

        const existingFiles = await getLocalFiles();
        existingFiles.sort(
            (a, b) => b.metadata.creationTime - a.metadata.creationTime
        );
        const files = existingFiles.slice(0, 50);

        this.allFaces = [];
        for (const file of files) {
            try {
                const result = await this.syncFile(file, token);
                this.allFaces = this.allFaces.concat(result);
                console.log('TF Memory stats: ', tf.memory());
            } catch (e) {
                console.error(
                    'Error while syncing file: ',
                    file.id.toString(),
                    e
                );
            }
        }
        console.log('allFaces: ', this.allFaces);

        const clusterResults = this.clusteringService.clusterUsingDBSCAN(
            this.allFaces.map((f) => f.embedding),
            this.clusterFaceDistance,
            this.minClusterSize
        );

        console.log('[MLService] Got cluster results: ', clusterResults);

        return {
            allFaces: this.allFaces,
            clusterResults,
        };
    }

    private async syncFile(file: File, token: string) {
        if (!token) {
            throw Error('Token needed by ml service to sync file');
        }

        const fileUrl = await DownloadManager.getPreview(file, token);
        console.log('[MLService] Got thumbnail: ', file.id.toString(), fileUrl);

        const thumbFile = await fetch(fileUrl);
        const arrayBuffer = await thumbFile.arrayBuffer();
        const decodedImg = await jpeg.decode(arrayBuffer);
        console.log('[MLService] decodedImg: ', decodedImg);

        const tfImage = tf.browser.fromPixels(decodedImg);

        const faces = await this.faceDetectionService.estimateFaces(tfImage);
        const embeddingResults = await this.faceEmbeddingService.getEmbeddings(
            tfImage,
            faces
        );
        tf.dispose(tfImage);
        console.log('[MLService] Got faces: ', faces, embeddingResults);

        return faces.map((face, index) => {
            return {
                fileId: file.id.toString(),
                face: face,
                embedding: embeddingResults.embeddings[index],
                faceImage: embeddingResults.faceImages[index],
            } as FaceWithEmbedding;
        });
    }
}

export default MachineLearningService;
