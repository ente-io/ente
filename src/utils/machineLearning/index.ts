import * as tf from '@tensorflow/tfjs-core';
import { Box } from 'face-api.js/build/es6';

export function f32Average(descriptors: Float32Array[]) {
    if (descriptors.length < 1) {
        throw Error('f32Average: input size 0');
    }

    if (descriptors.length === 1) {
        return descriptors[0];
    }

    const f32Size = descriptors[0].length;
    const avg = new Float32Array(f32Size);

    for (let index = 0; index < f32Size; index++) {
        avg[index] = descriptors[0][index];
        for (let desc = 1; desc < descriptors.length; desc++) {
            avg[index] = avg[index] + descriptors[desc][index];
        }
        avg[index] = avg[index] / descriptors.length;
    }

    return avg;
}

export function extractFaces(
    image: tf.Tensor3D,
    facebBoxes: Array<Box>,
    faceSize: number
) {
    return tf.tidy(() => {
        const reshapedImage = tf.expandDims(
            tf.cast(image as tf.Tensor, 'float32'),
            0
        ) as tf.Tensor4D;

        const boxes = facebBoxes.map((box) => {
            const normalized = box.rescale({
                width: 1 / reshapedImage.shape[2],
                height: 1 / reshapedImage.shape[1],
            });

            return [
                normalized.top,
                normalized.left,
                normalized.bottom,
                normalized.right,
            ];
        });

        // console.log('boxes: ', boxes[0]);

        const faceImagesTensor = tf.image.cropAndResize(
            reshapedImage,
            boxes,
            tf.fill([boxes.length], 0, 'int32'),
            [faceSize, faceSize]
        );

        return faceImagesTensor;
    });
}
