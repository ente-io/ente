import { Box, Point, boxFromBoundingBox } from "services/face/geom";
import { FaceDetection } from "services/face/types";
// TODO-ML: Do we need two separate Matrix libraries?
//
// Keeping this in a separate file so that we can audit this. If these can be
// expressed using ml-matrix, then we can move the code to f-index.
import {
    Matrix,
    applyToPoint,
    compose,
    scale,
    translate,
} from "transformation-matrix";

/**
 * Transform the given {@link faceDetections} from their coordinate system in
 * which they were detected ({@link inBox}) back to the coordinate system of the
 * original image ({@link toBox}).
 */
export const transformFaceDetections = (
    faceDetections: FaceDetection[],
    inBox: Box,
    toBox: Box,
): FaceDetection[] => {
    const transform = computeTransformToBox(inBox, toBox);
    return faceDetections.map((f) => {
        const box = transformBox(f.box, transform);
        const normLandmarks = f.landmarks;
        const landmarks = transformPoints(normLandmarks, transform);
        return {
            box,
            landmarks,
            probability: f.probability as number,
        } as FaceDetection;
    });
};

function computeTransformToBox(inBox: Box, toBox: Box): Matrix {
    return compose(
        translate(toBox.x, toBox.y),
        scale(toBox.width / inBox.width, toBox.height / inBox.height),
    );
}

function transformPoint(point: Point, transform: Matrix) {
    const txdPoint = applyToPoint(transform, point);
    return new Point(txdPoint.x, txdPoint.y);
}

function transformPoints(points: Point[], transform: Matrix) {
    return points?.map((p) => transformPoint(p, transform));
}

function transformBox(box: Box, transform: Matrix) {
    const topLeft = transformPoint(box.topLeft, transform);
    const bottomRight = transformPoint(box.bottomRight, transform);

    return boxFromBoundingBox({
        left: topLeft.x,
        top: topLeft.y,
        right: bottomRight.x,
        bottom: bottomRight.y,
    });
}
