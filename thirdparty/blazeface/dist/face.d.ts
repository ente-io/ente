/**
 * @license
 * Copyright 2019 Google LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 */
import * as tfconv from '@tensorflow/tfjs-converter';
import * as tf from '@tensorflow/tfjs-core';
import { Box } from './box';
export interface NormalizedFace {
    /** The upper left-hand corner of the face. */
    topLeft: [number, number] | tf.Tensor1D;
    /** The lower right-hand corner of the face. */
    bottomRight: [number, number] | tf.Tensor1D;
    /** Facial landmark coordinates. */
    landmarks?: number[][] | tf.Tensor2D;
    /** Probability of the face detection. */
    probability?: number | tf.Tensor1D;
}
export declare type BlazeFacePrediction = {
    box: Box;
    landmarks: tf.Tensor2D;
    probability: tf.Tensor1D;
    anchor: tf.Tensor2D | [number, number];
};
export declare class BlazeFaceModel {
    private blazeFaceModel;
    private width;
    private height;
    private maxFaces;
    private anchors;
    private anchorsData;
    private inputSize;
    private iouThreshold;
    private scoreThreshold;
    constructor(model: tfconv.GraphModel, width: number, height: number, maxFaces: number, iouThreshold: number, scoreThreshold: number);
    resizeAspectRatio(inputImage: tf.Tensor4D, width: number, height: number): {
        ratio: number;
        image: tf.Tensor<tf.Rank.R4>;
    };
    getBoundingBoxes(inputImage: tf.Tensor4D, returnTensors: boolean, annotateBoxes?: boolean): Promise<{
        boxes: Array<BlazeFacePrediction | Box>;
        scaleFactor: tf.Tensor | [number, number];
    }>;
    /**
     * Returns an array of faces in an image.
     *
     * @param input The image to classify. Can be a tensor, DOM element image,
     * video, or canvas.
     * @param returnTensors (defaults to `false`) Whether to return tensors as
     * opposed to values.
     * @param flipHorizontal Whether to flip/mirror the facial keypoints
     * horizontally. Should be true for videos that are flipped by default (e.g.
     * webcams).
     * @param annotateBoxes (defaults to `true`) Whether to annotate bounding
     * boxes with additional properties such as landmarks and probability. Pass in
     * `false` for faster inference if annotations are not needed.
     *
     * @return An array of detected faces, each with the following properties:
     *  `topLeft`: the upper left coordinate of the face in the form `[x, y]`
     *  `bottomRight`: the lower right coordinate of the face in the form `[x, y]`
     *  `landmarks`: facial landmark coordinates
     *  `probability`: the probability of the face being present
     */
    estimateFaces(input: tf.Tensor3D | ImageData | HTMLVideoElement | HTMLImageElement | HTMLCanvasElement, returnTensors?: boolean, flipHorizontal?: boolean, annotateBoxes?: boolean): Promise<NormalizedFace[]>;
    /**
     * Dispose the WebGL memory held by the underlying model.
     */
    dispose(): void;
}
