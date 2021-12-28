import { Box, Point } from '../../../thirdparty/face-api/classes';
import { Matrix } from 'ml-matrix';
import { newBoxFromPoints } from '.';

export function translation(x: number, y: number) {
    return new Matrix([
        [1, 0, x],
        [0, 1, y],
        [0, 0, 1],
    ]);
}

export function scale(sx: number, sy: number) {
    return new Matrix([
        [sx, 0, 0],
        [0, sy, 0],
        [0, 0, 1],
    ]);
}

export function rotation(angle: number) {
    const cosa = Math.cos(angle);
    const sina = Math.sin(angle);
    return new Matrix([
        [cosa, -sina, 0],
        [sina, cosa, 0],
        [0, 0, 1],
    ]);
}

export function computeTransformToBox(inBox: Box, toBox: Box): Matrix {
    return translation(toBox.x, toBox.y).mmul(
        scale(toBox.width / inBox.width, toBox.height / inBox.height)
    );
}

export function pointToArray(point: Point) {
    return [point.x, point.y];
}

export function transformPointVec(point: number[], transform: Matrix) {
    point[2] = 1;
    const mat = new Matrix([point]).transpose();
    const mulmat = new Matrix(transform).mmul(mat).to1DArray();
    // console.log({point, mat, mulmat});

    return mulmat;
}

export function transformPoint(point: Point, transform: Matrix) {
    const pointVec = transformPointVec(pointToArray(point), transform);
    return new Point(pointVec[0], pointVec[1]);
}

export function transformPoints(points: Point[], transform: Matrix) {
    return points.map((p) => transformPoint(p, transform));
}

export function transformBox(box: Box, transform: Matrix) {
    const topLeft = transformPoint(box.topLeft, transform);
    const bottomRight = transformPoint(box.bottomRight, transform);

    return newBoxFromPoints(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
}
