import {
    DEFAULT_ML_SYNC_CONFIG,
    DEFAULT_ML_SYNC_JOB_CONFIG,
} from 'constants/machineLearning/config';
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
