import { JobResult, SimpleJob } from 'utils/common/job';
import { MLSyncResult } from 'types/machineLearning';

export interface MLSyncJobResult extends JobResult {
    mlSyncResult: MLSyncResult;
}

export class MLSyncJob extends SimpleJob<MLSyncJobResult> {}
