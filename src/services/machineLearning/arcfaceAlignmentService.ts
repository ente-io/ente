import {
    ARCFACE_LANDMARKS,
    getAlignedFaceUsingSimilarityTransform,
} from 'utils/machineLearning/faceAlign';
import {
    AlignedFace,
    DetectedFace,
    FaceAlignmentService,
} from 'utils/machineLearning/types';

export default class ArcfaceAlignmentService implements FaceAlignmentService {
    public getAlignedFaces(faces: Array<DetectedFace>): Array<AlignedFace> {
        const alignedFaces = new Array<AlignedFace>(faces.length);

        faces.forEach((face, index) => {
            alignedFaces[index] = getAlignedFaceUsingSimilarityTransform(
                face,
                ARCFACE_LANDMARKS,
                { value: 'ArcFace', version: 1 }
            );
        });

        return alignedFaces;
    }
}
