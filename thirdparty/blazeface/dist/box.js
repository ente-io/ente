"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
var tf = require("@tensorflow/tfjs-core");
exports.disposeBox = function (box) {
    box.startEndTensor.dispose();
    box.startPoint.dispose();
    box.endPoint.dispose();
};
exports.createBox = function (startEndTensor) { return ({
    startEndTensor: startEndTensor,
    startPoint: tf.slice(startEndTensor, [0, 0], [-1, 2]),
    endPoint: tf.slice(startEndTensor, [0, 2], [-1, 2])
}); };
exports.scaleBox = function (box, factors) {
    var starts = tf.mul(box.startPoint, factors);
    var ends = tf.mul(box.endPoint, factors);
    var newCoordinates = tf.concat2d([starts, ends], 1);
    return exports.createBox(newCoordinates);
};
//# sourceMappingURL=box.js.map