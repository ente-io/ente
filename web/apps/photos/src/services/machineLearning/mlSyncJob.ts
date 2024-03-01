import { JobResult } from "types/common/job";
import { MLSyncResult } from "types/machineLearning";
import { SimpleJob } from "utils/common/job";

export interface MLSyncJobResult extends JobResult {
    mlSyncResult: MLSyncResult;
}

export class MLSyncJob extends SimpleJob<MLSyncJobResult> {}
