import {
    DEFAULT_ML_SEARCH_CONFIG,
    DEFAULT_ML_SYNC_CONFIG,
    DEFAULT_ML_SYNC_JOB_CONFIG,
} from "constants/mlConfig";
import { MLSearchConfig, MLSyncConfig } from "services/ml/types";
import { JobConfig } from "types/common/job";
import mlIDbStorage, {
    ML_SEARCH_CONFIG_NAME,
    ML_SYNC_CONFIG_NAME,
    ML_SYNC_JOB_CONFIG_NAME,
} from "utils/storage/mlIDbStorage";
import { isInternalUserForML } from "utils/user";

export async function getMLSyncJobConfig() {
    return mlIDbStorage.getConfig(
        ML_SYNC_JOB_CONFIG_NAME,
        DEFAULT_ML_SYNC_JOB_CONFIG,
    );
}

export async function getMLSyncConfig() {
    return mlIDbStorage.getConfig(ML_SYNC_CONFIG_NAME, DEFAULT_ML_SYNC_CONFIG);
}

export async function getMLSearchConfig() {
    if (isInternalUserForML()) {
        return mlIDbStorage.getConfig(
            ML_SEARCH_CONFIG_NAME,
            DEFAULT_ML_SEARCH_CONFIG,
        );
    }
    // Force disabled for everyone else while we finalize it to avoid redundant
    // reindexing for users.
    return DEFAULT_ML_SEARCH_CONFIG;
}

export async function updateMLSyncJobConfig(newConfig: JobConfig) {
    return mlIDbStorage.putConfig(ML_SYNC_JOB_CONFIG_NAME, newConfig);
}

export async function updateMLSyncConfig(newConfig: MLSyncConfig) {
    return mlIDbStorage.putConfig(ML_SYNC_CONFIG_NAME, newConfig);
}

export async function updateMLSearchConfig(newConfig: MLSearchConfig) {
    return mlIDbStorage.putConfig(ML_SEARCH_CONFIG_NAME, newConfig);
}
