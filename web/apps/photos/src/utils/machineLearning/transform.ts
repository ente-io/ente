import { newBoxFromPoints } from ".";
import { Box, Point } from "../../../thirdparty/face-api/classes";

import {
    Matrix,
    applyToPoint,
    compose,
    scale,
    translate,
} from "transformation-matrix";

export function computeTransformToBox(inBox: Box, toBox: Box): Matrix {
    return compose(
        translate(toBox.x, toBox.y),
        scale(toBox.width / inBox.width, toBox.height / inBox.height),
    );
}

export function transformPoint(point: Point, transform: Matrix) {
    const txdPoint = applyToPoint(transform, point);
    return new Point(txdPoint.x, txdPoint.y);
}

export function transformPoints(points: Point[], transform: Matrix) {
    return points?.map((p) => transformPoint(p, transform));
}

export function transformBox(box: Box, transform: Matrix) {
    const topLeft = transformPoint(box.topLeft, transform);
    const bottomRight = transformPoint(box.bottomRight, transform);

    return newBoxFromPoints(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
}
