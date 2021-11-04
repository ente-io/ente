import { MLSyncResult } from 'utils/machineLearning/types';

class MachineLearningService {
    public constructor() {}

    public async init() {}

    public async sync(token: string): Promise<MLSyncResult> {
        if (!token) {
            console.warn('No token provided');
        }
        return {
            allFaces: [],
        };
    }
}

export default MachineLearningService;
