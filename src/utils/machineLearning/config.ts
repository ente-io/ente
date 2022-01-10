import {
    DEFAULT_ML_SYNC_CONFIG,
    DEFAULT_ML_SYNC_JOB_CONFIG,
} from 'constants/machineLearning/config';
import { JobConfig } from 'types/common/job';
import { MLSyncConfig } from 'types/machineLearning';
import mlIDbStorage, {
    ML_SYNC_CONFIG_NAME,
    ML_SYNC_JOB_CONFIG_NAME,
} from 'utils/storage/mlIDbStorage';

export async function getMLSyncJobConfig() {
    return mlIDbStorage.getConfig(
        ML_SYNC_JOB_CONFIG_NAME,
        DEFAULT_ML_SYNC_JOB_CONFIG
    );
}

export async function getMLSyncConfig() {
    return mlIDbStorage.getConfig(ML_SYNC_CONFIG_NAME, DEFAULT_ML_SYNC_CONFIG);
}

export async function updateMLSyncJobConfig(newConfig: JobConfig) {
    return mlIDbStorage.putConfig(ML_SYNC_JOB_CONFIG_NAME, newConfig);
}

export async function updateMLSyncConfig(newConfig: MLSyncConfig) {
    return mlIDbStorage.putConfig(ML_SYNC_CONFIG_NAME, newConfig);
}
