import { Box } from "services/ml/geom";
import {
    FaceAlignment,
    FaceCrop,
    FaceCropConfig,
    FaceCropMethod,
    FaceCropService,
    FaceDetection,
    Versioned,
} from "services/ml/types";
import { cropWithRotation } from "utils/image";
import { getArcfaceAlignment } from "utils/machineLearning/faceAlign";
import { enlargeBox } from "utils/machineLearning/index";

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
        config: FaceCropConfig,
    ): Promise<FaceCrop> {
        const alignedFace = getArcfaceAlignment(faceDetection);
        const faceCrop = getFaceCrop(imageBitmap, alignedFace, config);

        return faceCrop;
    }
}

export default new ArcFaceCropService();

export function getFaceCrop(
    imageBitmap: ImageBitmap,
    alignment: FaceAlignment,
    config: FaceCropConfig,
): FaceCrop {
    const alignmentBox = new Box({
        x: alignment.center.x - alignment.size / 2,
        y: alignment.center.y - alignment.size / 2,
        width: alignment.size,
        height: alignment.size,
    }).round();
    const scaleForPadding = 1 + config.padding * 2;
    const paddedBox = enlargeBox(alignmentBox, scaleForPadding).round();
    const faceImageBitmap = cropWithRotation(imageBitmap, paddedBox, 0, {
        width: config.maxSize,
        height: config.maxSize,
    });

    return {
        image: faceImageBitmap,
        imageBox: paddedBox,
    };
}
