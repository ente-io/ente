import * as tf from "@tensorflow/tfjs-core";
import { Matrix, inverse } from "ml-matrix";
import { getSimilarityTransformation } from "similarity-transformation";
import { Dimensions } from "types/image";
import { FaceAlignment, FaceDetection } from "types/machineLearning";
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
): Array<[number, number]> {
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
    // log.info({ affineMatrix, meanTranslation, centerMat, center, toMean: simTransform.toMean, fromMean: simTransform.fromMean, size });

    return {
        affineMatrix,
        center,
        size,
        rotation,
    };
}

const ARCFACE_LANDMARKS = [
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [56.1396, 92.2848],
] as Array<[number, number]>;

const ARCFACE_LANDMARKS_FACE_SIZE = 112;

const ARC_FACE_5_LANDMARKS = [
    [38.2946, 51.6963],
    [73.5318, 51.5014],
    [56.0252, 71.7366],
    [41.5493, 92.3655],
    [70.7299, 92.2041],
] as Array<[number, number]>;

export function getArcfaceAlignment(
    faceDetection: FaceDetection,
): FaceAlignment {
    const landmarkCount = faceDetection.landmarks.length;
    return getFaceAlignmentUsingSimilarityTransform(
        faceDetection,
        normalizeLandmarks(
            landmarkCount === 5 ? ARC_FACE_5_LANDMARKS : ARCFACE_LANDMARKS,
            ARCFACE_LANDMARKS_FACE_SIZE,
        ),
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

// Used in MLDebugViewOnly
export function ibExtractFaceImageUsingTransform(
    image: ImageBitmap,
    alignment: FaceAlignment,
    faceSize: number,
): ImageBitmap {
    const scaledMatrix = new Matrix(alignment.affineMatrix)
        .mul(faceSize)
        .to2DArray();
    // log.info("scaledMatrix: ", scaledMatrix);
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
