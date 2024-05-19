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

export interface IRect {
    x: number;
    y: number;
    width: number;
    height: number;
}

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

export const enlargeBox = (box: Box, factor: number) => {
    const center = new Point(box.x + box.width / 2, box.y + box.height / 2);
    const newWidth = factor * box.width;
    const newHeight = factor * box.height;

    return new Box({
        x: center.x - newWidth / 2,
        y: center.y - newHeight / 2,
        width: newWidth,
        height: newHeight,
    });
};
