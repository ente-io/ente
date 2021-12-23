import { AlignedFace, DetectedFace } from 'types/machineLearning';
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
import { cropWithRotation, transform } from 'utils/image';
import {
    ARCFACE_LANDMARKS,
    ARCFACE_LANDMARKS_FACE_SIZE,
} from 'types/machineLearning/archface';
import { Box, Point } from '../../../thirdparty/face-api/classes';
import { Dimensions } from 'types/image';

export function normalizeLandmarks(
    landmarks: Array<[number, number]>,
    faceSize: number
) {
    return landmarks.map((landmark) =>
        landmark.map((p) => p / faceSize)
    ) as Array<[number, number]>;
}

export function getAlignedFaceUsingSimilarityTransform(
    face: DetectedFace,
    alignedLandmarks: Array<[number, number]>
    // alignmentMethod: Versioned<FaceAlignmentMethod>
): AlignedFace {
    const landmarksMat = new Matrix(
        face.landmarks.map((p) => [p.x, p.y]).slice(0, alignedLandmarks.length)
    ).transpose();
    const alignedLandmarksMat = new Matrix(alignedLandmarks).transpose();

    const simTransform = getSimilarityTransformation(
        landmarksMat,
        alignedLandmarksMat
    );

    const RS = Matrix.mul(simTransform.rotation, simTransform.scale);
    const TR = simTransform.translation;

    const affineMatrix = [
        [RS.get(0, 0), RS.get(0, 1), TR.get(0, 0)],
        [RS.get(1, 0), RS.get(1, 1), TR.get(1, 0)],
        [0, 0, 1],
    ];

    const size = 1 / simTransform.scale;
    const meanTranslation = simTransform.toMean.sub(0.5).mul(size);
    const centerMat = simTransform.fromMean.sub(meanTranslation);
    const center = new Point(centerMat.get(0, 0), centerMat.get(1, 0));
    const rotation = -Math.atan2(
        simTransform.rotation.get(0, 1),
        simTransform.rotation.get(0, 0)
    );
    // console.log({ affineMatrix, meanTranslation, centerMat, center, toMean: simTransform.toMean, fromMean: simTransform.fromMean, size });

    return {
        ...face,

        affineMatrix,
        center,
        size,
        rotation,
        // alignmentMethod,
    };
}

export function getArcfaceAlignedFace(face: DetectedFace): AlignedFace {
    return getAlignedFaceUsingSimilarityTransform(
        face,
        normalizeLandmarks(ARCFACE_LANDMARKS, ARCFACE_LANDMARKS_FACE_SIZE)
    );
}

export function extractFaceImage(
    image: tf.Tensor4D,
    alignedFace: AlignedFace,
    faceSize: number
) {
    const affineMat = new Matrix(alignedFace.affineMatrix);

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

export function extractFaceImages(
    image: tf.Tensor3D | tf.Tensor4D,
    faces: AlignedFace[],
    faceSize: number
): tf.Tensor4D {
    return tf.tidy(() => {
        const tf4dFloat32Image = toTensor4D(image, 'float32');
        const faceImages = new Array<tf.Tensor3D>(faces.length);
        for (let i = 0; i < faces.length; i++) {
            faceImages[i] = extractFaceImage(
                tf4dFloat32Image,
                faces[i],
                faceSize
            ).squeeze([0]);
        }

        return tf.stack(faceImages) as tf.Tensor4D;
    });
}

export function getAlignedFaceBox(alignedFace: AlignedFace) {
    return new Box({
        x: alignedFace.center.x - alignedFace.size / 2,
        y: alignedFace.center.y - alignedFace.size / 2,
        width: alignedFace.size,
        height: alignedFace.size,
    }).round();
}

export function ibExtractFaceImage(
    image: ImageBitmap,
    alignedFace: AlignedFace,
    faceSize: number
): ImageBitmap {
    const box = getAlignedFaceBox(alignedFace);
    const faceSizeDimentions: Dimensions = {
        width: faceSize,
        height: faceSize,
    };
    return cropWithRotation(
        image,
        box,
        alignedFace.rotation,
        faceSizeDimentions,
        faceSizeDimentions
    );
}

export function ibExtractFaceImageUsingTransform(
    image: ImageBitmap,
    alignedFace: AlignedFace,
    faceSize: number
): ImageBitmap {
    const scaledMatrix = new Matrix(alignedFace.affineMatrix)
        .mul(faceSize)
        .to2DArray();
    // console.log("scaledMatrix: ", scaledMatrix);
    return transform(image, scaledMatrix, faceSize, faceSize);
}

export function ibExtractFaceImages(
    image: ImageBitmap,
    faces: AlignedFace[],
    faceSize: number
): tf.Tensor4D {
    return tf.tidy(() => {
        const faceImages = new Array<tf.Tensor3D>(faces.length);
        for (let i = 0; i < faces.length; i++) {
            const faceImageBitmap = ibExtractFaceImage(
                image,
                faces[i],
                faceSize
            );
            faceImages[i] = tf.browser.fromPixels(faceImageBitmap);
            faceImageBitmap.close();
        }

        return tf.stack(faceImages) as tf.Tensor4D;
    });
}

export function extractArcfaceAlignedFaceImage(
    image: tf.Tensor4D,
    face: DetectedFace,
    faceSize: number
): tf.Tensor4D {
    const alignedFace = getAlignedFaceUsingSimilarityTransform(
        face,
        ARCFACE_LANDMARKS
    );

    return extractFaceImage(image, alignedFace, faceSize);
}

export function extractArcfaceAlignedFaceImages(
    image: tf.Tensor3D | tf.Tensor4D,
    faces: DetectedFace[],
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
    face: DetectedFace,
    padding: number = 1.5
): tf.Tensor4D {
    const paddedBox = enlargeBox(face.box, padding);
    // console.log("paddedBox", paddedBox);
    const landmarkPoints = face.landmarks;

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
        // console.log('angle: ', angle);

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
