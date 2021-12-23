import { getArcfaceAlignedFace } from 'utils/machineLearning/faceAlign';
import {
    AlignedFace,
    DetectedFace,
    FaceAlignmentMethod,
    FaceAlignmentService,
    Versioned,
} from 'types/machineLearning';

class ArcfaceAlignmentService implements FaceAlignmentService {
    public method: Versioned<FaceAlignmentMethod>;

    constructor() {
        this.method = {
            value: 'ArcFace',
            version: 1,
        };
    }

    public getAlignedFaces(faces: Array<DetectedFace>): Array<AlignedFace> {
        const alignedFaces = new Array<AlignedFace>(faces.length);

        faces.forEach((face, index) => {
            alignedFaces[index] = getArcfaceAlignedFace(face);
        });

        return alignedFaces;
    }
}

export default new ArcfaceAlignmentService();
