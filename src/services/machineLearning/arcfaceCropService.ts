import {
    DetectedFace,
    FaceCrop,
    FaceCropConfig,
    FaceCropMethod,
    FaceCropService,
    Versioned,
} from 'types/machineLearning';
import { getArcfaceAlignedFace } from 'utils/machineLearning/faceAlign';
import { getFaceCrop } from 'utils/machineLearning/faceCrop';

class ArcFaceCropService implements FaceCropService {
    public method: Versioned<FaceCropMethod>;

    constructor() {
        this.method = {
            value: 'ArcFace',
            version: 1,
        };
    }

    public async getFaceCrop(
        imageBitmap: ImageBitmap,
        face: DetectedFace,
        config: FaceCropConfig
    ): Promise<FaceCrop> {
        const alignedFace = getArcfaceAlignedFace(face);
        const faceCrop = getFaceCrop(imageBitmap, alignedFace, config);

        return faceCrop;
    }
}

export default new ArcFaceCropService();
