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
import * as tf from '@tensorflow/tfjs-core';
import { BlazeFaceModel } from './face';
interface BlazeFaceConfig {
    maxFaces?: number;
    inputWidth?: number;
    inputHeight?: number;
    iouThreshold?: number;
    scoreThreshold?: number;
    modelUrl?: string | tf.io.IOHandler;
}
/**
 * Load blazeface.
 *
 * @param config A configuration object with the following properties:
 *  `maxFaces` The maximum number of faces returned by the model.
 *  `inputWidth` The width of the input image.
 *  `inputHeight` The height of the input image.
 *  `iouThreshold` The threshold for deciding whether boxes overlap too
 * much.
 *  `scoreThreshold` The threshold for deciding when to remove boxes based
 * on score.
 */
export declare function load({ maxFaces, inputWidth, inputHeight, iouThreshold, scoreThreshold, modelUrl, }?: BlazeFaceConfig): Promise<BlazeFaceModel>;
export { NormalizedFace, BlazeFaceModel, BlazeFacePrediction } from './face';
