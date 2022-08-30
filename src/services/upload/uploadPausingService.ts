import { IsUploadPausing } from 'types/upload';

class UploadPausingService {
    private uploadPausing: IsUploadPausing = {
        val: false,
    };

    setUploadPausing(isPausing: boolean) {
        this.uploadPausing.val = isPausing;
    }

    isUploadPausing(): boolean {
        return this.uploadPausing.val;
    }
}

export default new UploadPausingService();
