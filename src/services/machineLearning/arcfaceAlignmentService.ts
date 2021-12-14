import {
    ARCFACE_LANDMARKS,
    getAlignedFaceUsingSimilarityTransform,
} from 'utils/machineLearning/faceAlign';
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
            alignedFaces[index] = getAlignedFaceUsingSimilarityTransform(
                face,
                ARCFACE_LANDMARKS
                // this.method
            );
        });

        return alignedFaces;
    }
}

export default new ArcfaceAlignmentService();
