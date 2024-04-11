import { Matrix } from "ml-matrix";
import { getSimilarityTransformation } from "similarity-transformation";
import { FaceAlignment, FaceDetection } from "types/machineLearning";
import { Point } from "../../../thirdparty/face-api/classes";

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

function getFaceAlignmentUsingSimilarityTransform(
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

function normalizeLandmarks(
    landmarks: Array<[number, number]>,
    faceSize: number,
): Array<[number, number]> {
    return landmarks.map((landmark) =>
        landmark.map((p) => p / faceSize),
    ) as Array<[number, number]>;
}
