import {
    FaceCrop,
    FaceCropConfig,
    FaceCropMethod,
    FaceCropService,
    FaceDetection,
    Versioned,
} from "types/machineLearning";
import { getArcfaceAlignment } from "utils/machineLearning/faceAlign";
import { getFaceCrop } from "utils/machineLearning/faceCrop";

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
