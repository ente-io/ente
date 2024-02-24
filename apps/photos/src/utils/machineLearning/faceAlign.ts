import * as tf from "@tensorflow/tfjs-core";
import { Matrix, inverse } from "ml-matrix";
import { getSimilarityTransformation } from "similarity-transformation";
import { Dimensions } from "types/image";
import { FaceAlignment, FaceDetection } from "types/machineLearning";
import {
    ARCFACE_LANDMARKS,
    ARCFACE_LANDMARKS_FACE_SIZE,
} from "types/machineLearning/archface";
import { cropWithRotation, transform } from "utils/image";
import {
    computeRotation,
    enlargeBox,
    extractFaces,
    getBoxCenter,
    getBoxCenterPt,
    toTensor4D,
} from ".";
import { Box, Point } from "../../../thirdparty/face-api/classes";

export function normalizeLandmarks(
    landmarks: Array<[number, number]>,
    faceSize: number,
) {
    return landmarks.map((landmark) =>
        landmark.map((p) => p / faceSize),
    ) as Array<[number, number]>;
}

export function getFaceAlignmentUsingSimilarityTransform(
    faceDetection: FaceDetection,
    alignedLandmarks: Array<[number, number]>,
    // alignmentMethod: Versioned<FaceAlignmentMethod>
): FaceAlignment {
    const landmarksMat = new Matrix(
        faceDetection.landmarks
            .map((p) => [p.x, p.y])
            .slice(0, alignedLandmarks.length),
    ).transpose();
    const alignedLandmarksMat = new Matrix(alignedLandmarks).transpose();

    const simTransform = getSimilarityTransformation(
        landmarksMat,
        alignedLandmarksMat,
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
        simTransform.rotation.get(0, 0),
    );
    // addLogLine({ affineMatrix, meanTranslation, centerMat, center, toMean: simTransform.toMean, fromMean: simTransform.fromMean, size });

    return {
        affineMatrix,
        center,
        size,
        rotation,
    };
}

export function getArcfaceAlignment(
    faceDetection: FaceDetection,
): FaceAlignment {
    return getFaceAlignmentUsingSimilarityTransform(
        faceDetection,
        normalizeLandmarks(ARCFACE_LANDMARKS, ARCFACE_LANDMARKS_FACE_SIZE),
    );
}

export function extractFaceImage(
    image: tf.Tensor4D,
    alignment: FaceAlignment,
    faceSize: number,
) {
    const affineMat = new Matrix(alignment.affineMatrix);

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
            "bilinear",
            "constant",
            0,
            [faceSize, faceSize],
        );
        return faceImage;
    });
}

export function tfExtractFaceImages(
    image: tf.Tensor3D | tf.Tensor4D,
    alignments: Array<FaceAlignment>,
    faceSize: number,
): tf.Tensor4D {
    return tf.tidy(() => {
        const tf4dFloat32Image = toTensor4D(image, "float32");
        const faceImages = new Array<tf.Tensor3D>(alignments.length);
        for (let i = 0; i < alignments.length; i++) {
            faceImages[i] = tf.squeeze(
                extractFaceImage(tf4dFloat32Image, alignments[i], faceSize),
                [0],
            );
        }

        return tf.stack(faceImages) as tf.Tensor4D;
    });
}

export function getAlignedFaceBox(alignment: FaceAlignment) {
    return new Box({
        x: alignment.center.x - alignment.size / 2,
        y: alignment.center.y - alignment.size / 2,
        width: alignment.size,
        height: alignment.size,
    }).round();
}

export function ibExtractFaceImage(
    image: ImageBitmap,
    alignment: FaceAlignment,
    faceSize: number,
): ImageBitmap {
    const box = getAlignedFaceBox(alignment);
    const faceSizeDimentions: Dimensions = {
        width: faceSize,
        height: faceSize,
    };
    return cropWithRotation(
        image,
        box,
        alignment.rotation,
        faceSizeDimentions,
        faceSizeDimentions,
    );
}

export function ibExtractFaceImageUsingTransform(
    image: ImageBitmap,
    alignment: FaceAlignment,
    faceSize: number,
): ImageBitmap {
    const scaledMatrix = new Matrix(alignment.affineMatrix)
        .mul(faceSize)
        .to2DArray();
    // addLogLine("scaledMatrix: ", scaledMatrix);
    return transform(image, scaledMatrix, faceSize, faceSize);
}

export function ibExtractFaceImages(
    image: ImageBitmap,
    alignments: Array<FaceAlignment>,
    faceSize: number,
): Array<ImageBitmap> {
    return alignments.map((alignment) =>
        ibExtractFaceImage(image, alignment, faceSize),
    );
}

export function extractArcfaceAlignedFaceImage(
    image: tf.Tensor4D,
    faceDetection: FaceDetection,
    faceSize: number,
): tf.Tensor4D {
    const alignment = getFaceAlignmentUsingSimilarityTransform(
        faceDetection,
        ARCFACE_LANDMARKS,
    );

    return extractFaceImage(image, alignment, faceSize);
}

export function extractArcfaceAlignedFaceImages(
    image: tf.Tensor3D | tf.Tensor4D,
    faceDetections: Array<FaceDetection>,
    faceSize: number,
): tf.Tensor4D {
    return tf.tidy(() => {
        const tf4dFloat32Image = toTensor4D(image, "float32");
        const faceImages = new Array<tf.Tensor3D>(faceDetections.length);
        for (let i = 0; i < faceDetections.length; i++) {
            faceImages[i] = tf.squeeze(
                extractArcfaceAlignedFaceImage(
                    tf4dFloat32Image,
                    faceDetections[i],
                    faceSize,
                ),
                [0],
            );
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
    faceDetection: FaceDetection,
    padding: number = 1.5,
): tf.Tensor4D {
    const paddedBox = enlargeBox(faceDetection.box, padding);
    // addLogLine("paddedBox", paddedBox);
    const landmarkPoints = faceDetection.landmarks;

    return tf.tidy(() => {
        const tf4dFloat32Image = toTensor4D(image, "float32");
        let angle = 0;
        const leftEye = landmarkPoints[BLAZEFACE_LEFT_EYE_INDEX];
        const rightEye = landmarkPoints[BLAZEFACE_RIGHT_EYE_INDEX];
        const foreheadCenter = getBoxCenterPt(leftEye, rightEye);

        angle = computeRotation(
            landmarkPoints[BLAZEFACE_MOUTH_INDEX],
            foreheadCenter,
        ); // landmarkPoints[BLAZEFACE_NOSE_INDEX]
        // angle = computeRotation(leftEye, rightEye);
        // addLogLine('angle: ', angle);

        const faceCenter = getBoxCenter(faceDetection.box);
        // addLogLine('faceCenter: ', faceCenter);
        const faceCenterNormalized: [number, number] = [
            faceCenter.x / tf4dFloat32Image.shape[2],
            faceCenter.y / tf4dFloat32Image.shape[1],
        ];
        // addLogLine('faceCenterNormalized: ', faceCenterNormalized);

        let rotatedImage = tf4dFloat32Image;
        if (angle !== 0) {
            rotatedImage = tf.image.rotateWithOffset(
                tf4dFloat32Image,
                angle,
                0,
                faceCenterNormalized,
            );
        }

        const faceImageTensor = extractFaces(
            rotatedImage,
            [paddedBox],
            paddedBox.width > 224 ? 448 : 224,
        );
        return faceImageTensor;
        // return tf.gather(faceImageTensor, 0);
    });
}
