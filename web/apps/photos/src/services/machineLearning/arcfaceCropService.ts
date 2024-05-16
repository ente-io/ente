import { Box, enlargeBox } from "services/face/geom";
import {
    FaceAlignment,
    FaceCrop,
    FaceCropMethod,
    FaceCropService,
    FaceDetection,
    Versioned,
} from "services/face/types";
import { cropWithRotation } from "utils/image";
import { faceAlignment } from "../face/align";

class ArcFaceCropService implements FaceCropService {
    public method: Versioned<FaceCropMethod>;

    constructor() {
        this.method = {
            value: "ArcFace",
            version: 1,
        };
    }

    public async getFaceCrop(
        imageBitmap: ImageBitmap,
        faceDetection: FaceDetection,
    ): Promise<FaceCrop> {
        const alignment = faceAlignment(faceDetection);
        const faceCrop = getFaceCrop(imageBitmap, alignment);

        return faceCrop;
    }
}

export default new ArcFaceCropService();

export function getFaceCrop(
    imageBitmap: ImageBitmap,
    alignment: FaceAlignment,
): FaceCrop {
    const padding = 0.25;
    const maxSize = 256;

    const alignmentBox = new Box({
        x: alignment.center.x - alignment.size / 2,
        y: alignment.center.y - alignment.size / 2,
        width: alignment.size,
        height: alignment.size,
    }).round();
    const scaleForPadding = 1 + padding * 2;
    const paddedBox = enlargeBox(alignmentBox, scaleForPadding).round();
    const faceImageBitmap = cropWithRotation(imageBitmap, paddedBox, 0, {
        width: maxSize,
        height: maxSize,
    });

    return {
        image: faceImageBitmap,
        imageBox: paddedBox,
    };
}
