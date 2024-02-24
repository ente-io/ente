import {
    FaceAlignment,
    FaceAlignmentMethod,
    FaceAlignmentService,
    FaceDetection,
    Versioned,
} from "types/machineLearning";
import { getArcfaceAlignment } from "utils/machineLearning/faceAlign";

class ArcfaceAlignmentService implements FaceAlignmentService {
    public method: Versioned<FaceAlignmentMethod>;

    constructor() {
        this.method = {
            value: "ArcFace",
            version: 1,
        };
    }

    public getFaceAlignment(faceDetection: FaceDetection): FaceAlignment {
        return getArcfaceAlignment(faceDetection);
    }
}

export default new ArcfaceAlignmentService();
