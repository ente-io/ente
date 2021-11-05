import { File, getLocalFiles } from 'services/fileService';
import DownloadManager from 'services/downloadManager';

import * as tf from '@tensorflow/tfjs-core';
// import { setWasmPaths } from '@tensorflow/tfjs-backend-wasm';

// import TFJSFaceDetectionService from './tfjsFaceDetectionService';
// import TFJSFaceEmbeddingService from './tfjsFaceEmbeddingService';
import { FaceImage, MLSyncResult } from 'utils/machineLearning/types';

import * as jpeg from 'jpeg-js';
import ClusteringService from './clusteringService';

import './faceEnvPatch';
import * as faceapi from 'face-api.js';
import { SsdMobilenetv1Options } from 'face-api.js';

class MachineLearningService {
    // private faceDetectionService: TFJSFaceDetectionService;
    // private faceEmbeddingService: TFJSFaceEmbeddingService;
    private clusteringService: ClusteringService;

    private clusterFaceDistance = 0.45;
    private minClusterSize = 4;
    private minFaceSize = 24;

    public allFaces: faceapi.WithFaceDescriptor<
        faceapi.WithFaceLandmarks<
            {
                detection: faceapi.FaceDetection;
            },
            faceapi.FaceLandmarks68
        >
    >[];
    private allFaceImages: FaceImage[];

    public constructor() {
        // this.faceDetectionService = new TFJSFaceDetectionService();
        // this.faceEmbeddingService = new TFJSFaceEmbeddingService();
        this.clusteringService = new ClusteringService();

        this.allFaces = [];
        this.allFaceImages = [];
    }

    public async init(
        clusterFaceDistance: number,
        minClusterSize: number,
        minFaceSize: number
    ) {
        this.clusterFaceDistance = clusterFaceDistance;
        this.minClusterSize = minClusterSize;
        this.minFaceSize = minFaceSize;

        // setWasmPath('/js/tfjs/');
        await tf.ready();

        // await this.faceDetectionService.init();
        // await this.faceEmbeddingService.init();
        await faceapi.nets.ssdMobilenetv1.loadFromUri('/models/face-api/');
        await faceapi.nets.faceLandmark68Net.loadFromUri('/models/face-api/');
        await faceapi.nets.faceRecognitionNet.loadFromUri('/models/face-api/');
    }

    private getUniqueFiles(files: File[], limit: number) {
        const uniqueFiles: Map<number, File> = new Map<number, File>();
        for (let i = 0; uniqueFiles.size < limit && i < files.length; i++) {
            if (!uniqueFiles.has(files[i].id)) {
                uniqueFiles.set(files[i].id, files[i]);
            }
        }

        return uniqueFiles;
    }

    public async sync(token: string): Promise<MLSyncResult> {
        if (!token) {
            throw Error('Token needed by ml service to sync file');
        }

        const existingFiles = await getLocalFiles();
        existingFiles.sort(
            (a, b) => b.metadata.creationTime - a.metadata.creationTime
        );
        const files = this.getUniqueFiles(existingFiles, 50);
        console.log('Got unique files: ', files.size);

        this.allFaces = [];
        for (const file of files.values()) {
            try {
                const result = await this.syncFile(file, token);
                this.allFaces = this.allFaces.concat(result.faceApiResults);
                this.allFaceImages = this.allFaceImages.concat(
                    result.faceImages
                );
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
        // [0].alignedRect,
        // this.allFaces[0].alignedRect.box,
        // this.allFaces[0].alignedRect.imageDims

        const clusterResults = this.clusteringService.clusterUsingDBSCAN(
            this.allFaces.map((f) => Array.from(f.descriptor)),
            this.clusterFaceDistance,
            this.minClusterSize
        );

        // const clusterResults = this.clusteringService.clusterUsingKMEANS(
        //     this.allFaces.map((f) => f.embedding),
        //     10);

        console.log('[MLService] Got cluster results: ', clusterResults);

        return {
            allFaces: this.allFaceImages,
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

        // const faces = await this.faceDetectionService.estimateFaces(tfImage);

        // const embeddingResults = await this.faceEmbeddingService.getEmbeddings(
        //     tfImage,
        //     filtertedFaces
        // );

        const faceApiInput = tfImage.expandDims(0) as tf.Tensor4D;
        const faces = await faceapi
            .detectAllFaces(
                faceApiInput as any,
                new SsdMobilenetv1Options({
                    // minConfidence: 0.6
                    // maxResults: 10
                })
            )
            .withFaceLandmarks()
            .withFaceDescriptors();

        const filtertedFaces = faces.filter((face) => {
            return (
                face.alignedRect.box.width > this.minFaceSize // &&
                // face.alignedBox[3] - face.alignedBox[1] > this.minFacePixels
            );
        });
        console.log('filtertedFaces: ', filtertedFaces);

        // const embeddings = results.map(f=>f.descriptor);
        // console.log('embeddings', embeddings);
        let faceImages = [];
        if (filtertedFaces && filtertedFaces.length > 0) {
            const faceBoxes = filtertedFaces
                .map((f) => f.alignedRect.relativeBox)
                .map((b) => [b.top, b.left, b.bottom, b.right]);
            const normalizedImage = tf.sub(
                tf.div(faceApiInput, 127.5),
                1.0
            ) as tf.Tensor4D;
            const faceImagesTensor = tf.image.cropAndResize(
                normalizedImage,
                faceBoxes,
                tf.fill([faceBoxes.length], 0, 'int32'),
                [112, 112]
            );
            faceImages = await faceImagesTensor.array();
            // console.log(JSON.stringify(results));
        }

        tf.dispose(tfImage);

        return {
            faceApiResults: filtertedFaces,
            faceImages: faceImages,
        };

        // console.log('[MLService] Got faces: ', filtertedFaces, embeddingResults);

        // return filtertedFaces.map((face, index) => {
        //     return {
        //         fileId: file.id.toString(),
        //         face: face,
        //         embedding: embeddingResults.embeddings[index],
        //         faceImage: embeddingResults.faceImages[index],
        //     } as FaceWithEmbedding;
        // });
    }
}

export default MachineLearningService;
