export class Point {
    public x: number;
    public y: number;

    constructor(x: number, y: number) {
        this.x = x;
        this.y = y;
    }
}

export interface Dimensions {
    width: number;
    height: number;
}

export interface IBoundingBox {
    left: number;
    top: number;
    right: number;
    bottom: number;
}

export interface IRect {
    x: number;
    y: number;
    width: number;
    height: number;
}

export function newBox(x: number, y: number, width: number, height: number) {
    return new Box({ x, y, width, height });
}

export const boxFromBoundingBox = ({
    left,
    top,
    right,
    bottom,
}: IBoundingBox) => {
    return new Box({
        x: left,
        y: top,
        width: right - left,
        height: bottom - top,
    });
};

export class Box implements IRect {
    public x: number;
    public y: number;
    public width: number;
    public height: number;

    constructor({ x, y, width, height }: IRect) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    public get left(): number {
        return this.x;
    }
    public get top(): number {
        return this.y;
    }
    public get right(): number {
        return this.x + this.width;
    }
    public get bottom(): number {
        return this.y + this.height;
    }
    public get area(): number {
        return this.width * this.height;
    }
    public get topLeft(): Point {
        return new Point(this.left, this.top);
    }
    public get topRight(): Point {
        return new Point(this.right, this.top);
    }
    public get bottomLeft(): Point {
        return new Point(this.left, this.bottom);
    }
    public get bottomRight(): Point {
        return new Point(this.right, this.bottom);
    }

    public round(): Box {
        const [x, y, width, height] = [
            this.x,
            this.y,
            this.width,
            this.height,
        ].map((val) => Math.round(val));
        return new Box({ x, y, width, height });
    }
}
