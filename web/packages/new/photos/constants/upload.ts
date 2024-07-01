import type { Location } from "../types/metadata";

export const RANDOM_PERCENTAGE_PROGRESS_FOR_PUT = () => 90 + 10 * Math.random();

export const NULL_LOCATION: Location = { latitude: null, longitude: null };

export enum UPLOAD_STAGES {
    START,
    READING_GOOGLE_METADATA_FILES,
    EXTRACTING_METADATA,
    UPLOADING,
    CANCELLING,
    FINISH,
}

export enum UPLOAD_RESULT {
    FAILED,
    ALREADY_UPLOADED,
    UNSUPPORTED,
    BLOCKED,
    TOO_LARGE,
    LARGER_THAN_AVAILABLE_STORAGE,
    UPLOADED,
    UPLOADED_WITH_STATIC_THUMBNAIL,
    ADDED_SYMLINK,
}
