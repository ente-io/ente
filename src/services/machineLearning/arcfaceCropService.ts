import {
    DetectedFace,
    FaceCropConfig,
    FaceCropMethod,
    FaceCropService,
    StoredFaceCrop,
    Versioned,
} from 'types/machineLearning';
import { getArcfaceAlignedFace } from 'utils/machineLearning/faceAlign';
import { getFaceCrop, getStoredFaceCrop } from 'utils/machineLearning/faceCrop';

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
    ): Promise<StoredFaceCrop> {
        const alignedFace = getArcfaceAlignedFace(face);
        const faceCrop = getFaceCrop(imageBitmap, alignedFace, config);
        const storedFaceCrop = getStoredFaceCrop(faceCrop, config.blobOptions);
        faceCrop.image.close();

        return storedFaceCrop;
    }
}

export default new ArcFaceCropService();
