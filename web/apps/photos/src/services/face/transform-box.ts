import { Box, Point } from "services/face/geom";
import type { FaceDetection } from "services/face/types";
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
    const transform = boxTransformationMatrix(inBox, toBox);
    return faceDetections.map((f) => ({
        box: transformBox(f.box, transform),
        landmarks: f.landmarks.map((p) => transformPoint(p, transform)),
        probability: f.probability,
    }));
};

const boxTransformationMatrix = (inBox: Box, toBox: Box): Matrix =>
    compose(
        translate(toBox.x, toBox.y),
        scale(toBox.width / inBox.width, toBox.height / inBox.height),
    );

const transformPoint = (point: Point, transform: Matrix) => {
    const txdPoint = applyToPoint(transform, point);
    return new Point(txdPoint.x, txdPoint.y);
};

const transformBox = (box: Box, transform: Matrix) => {
    const topLeft = transformPoint(new Point(box.x, box.y), transform);
    const bottomRight = transformPoint(
        new Point(box.x + box.width, box.y + box.height),
        transform,
    );

    return new Box({
        x: topLeft.x,
        y: topLeft.y,
        width: bottomRight.x - topLeft.x,
        height: bottomRight.y - topLeft.y,
    });
};
