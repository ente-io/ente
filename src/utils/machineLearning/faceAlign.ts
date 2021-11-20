import { AlignedFace } from './types';
import { Matrix, inverse } from 'ml-matrix';
import * as tf from '@tensorflow/tfjs-core';
import { getSimilarityTransformation } from '../../../thirdparty/similarity-transformation-js/main';
import {
    computeRotation,
    enlargeBox,
    extractFaces,
    getBoxCenter,
    getBoxCenterPt,
    toTensor4D,
} from '.';
import { Point } from '../../../thirdparty/face-api/classes';

const ARCFACE_LANDMARKS = new Matrix([
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [56.1396, 92.2848],
]).transpose();

export function extractArcfaceAlignedFaceImage(
    image: tf.Tensor4D,
    face: AlignedFace,
    faceSize: number
): tf.Tensor4D {
    const landmarks = face.landmarks as number[][];
    const landmarksMat = new Matrix(landmarks.slice(0, 4)).transpose();

    const simTransform = getSimilarityTransformation(
        landmarksMat,
        ARCFACE_LANDMARKS
    );
    const RS = simTransform.rotScale;
    const TR = simTransform.translation;

    const affineMat = new Matrix([
        [RS.get(0, 0), RS.get(0, 1), TR.get(0, 0)],
        [RS.get(1, 0), RS.get(1, 1), TR.get(1, 0)],
        [0, 0, 1],
    ]);

    const I = inverse(affineMat);

    return tf.tidy(() => {
        const projection = tf.tensor2d([
            [
                I.get(0, 0),
                I.get(0, 1),
                I.get(0, 2),
                I.get(1, 0),
                I.get(1, 1),
                I.get(1, 2),
                0,
                0,
            ],
        ]);
        const faceImage = tf.image.transform(
            image,
            projection,
            'bilinear',
            'constant',
            0,
            [faceSize, faceSize]
        );
        return faceImage;
    });
}

export function extractArcfaceAlignedFaceImages(
    image: tf.Tensor3D | tf.Tensor4D,
    faces: AlignedFace[],
    faceSize: number
): tf.Tensor4D {
    return tf.tidy(() => {
        const tf4dFloat32Image = toTensor4D(image, 'float32');
        const faceImages = new Array<tf.Tensor3D>(faces.length);
        for (let i = 0; i < faces.length; i++) {
            faceImages[i] = extractArcfaceAlignedFaceImage(
                tf4dFloat32Image,
                faces[i],
                faceSize
            ).squeeze([0]);
        }

        return tf.stack(faceImages) as tf.Tensor4D;
    });
}

const BLAZEFACE_LEFT_EYE_INDEX = 0;
const BLAZEFACE_RIGHT_EYE_INDEX = 1;
// const BLAZEFACE_NOSE_INDEX = 2;
const BLAZEFACE_MOUTH_INDEX = 3;

export function getRotatedFaceImage(
    image: tf.Tensor3D | tf.Tensor4D,
    face: AlignedFace,
    padding: number = 1.5
): tf.Tensor4D {
    const paddedBox = enlargeBox(face.box, padding);
    // console.log("paddedBox", paddedBox);
    const landmarkPoints = (face.landmarks as Array<[number, number]>).map(
        (l) => new Point(l[0], l[1])
    );

    return tf.tidy(() => {
        const tf4dFloat32Image = toTensor4D(image, 'float32');
        let angle = 0;
        const leftEye = landmarkPoints[BLAZEFACE_LEFT_EYE_INDEX];
        const rightEye = landmarkPoints[BLAZEFACE_RIGHT_EYE_INDEX];
        const foreheadCenter = getBoxCenterPt(leftEye, rightEye);

        angle = computeRotation(
            landmarkPoints[BLAZEFACE_MOUTH_INDEX],
            foreheadCenter
        ); // landmarkPoints[BLAZEFACE_NOSE_INDEX]
        // angle = computeRotation(leftEye, rightEye);
        console.log('angle: ', angle);

        const faceCenter = getBoxCenter(face.box);
        // console.log('faceCenter: ', faceCenter);
        const faceCenterNormalized: [number, number] = [
            faceCenter.x / tf4dFloat32Image.shape[2],
            faceCenter.y / tf4dFloat32Image.shape[1],
        ];
        // console.log('faceCenterNormalized: ', faceCenterNormalized);

        let rotatedImage = tf4dFloat32Image;
        if (angle !== 0) {
            rotatedImage = tf.image.rotateWithOffset(
                tf4dFloat32Image,
                angle,
                0,
                faceCenterNormalized
            );
        }

        const faceImageTensor = extractFaces(
            rotatedImage,
            [paddedBox],
            paddedBox.width > 224 ? 448 : 224
        );
        return faceImageTensor;
        // return tf.gather(faceImageTensor, 0);
    });
}
