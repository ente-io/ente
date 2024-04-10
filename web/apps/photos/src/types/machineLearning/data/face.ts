/// [`x`] and [y] are the coordinates of the top left corner of the box, so the minimim values
/// [width] and [height] are the width and height of the box.
/// All values are in absolute pixels relative to the original image size.
export interface CenterBox {
    x: number;
    y: number;
    height: number;
    width: number;
}

export interface Point {
    x: number;
    y: number;
}

export interface Detection {
    box: CenterBox;
    landmarks: Point[];
}

export interface Face {
    id: string;
    confidence: number;
    blur: number;
    embedding: Float32Array;
    detection: Detection;
}
