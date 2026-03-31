import { apiOrigin } from "ente-base/origins";

export const LOCKER_FILE_LIMIT_FREE = 100;
export const LOCKER_FILE_LIMIT_PAID = 1000;
export const LOCKER_MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024 * 1024;
export const LOCKER_STORAGE_BUFFER_BYTES = 20 * 1024 * 1024;

const ENTE_PRODUCTION_API_ORIGIN = "https://api.ente.io";

const normalizedOrigin = (origin: string) => new URL(origin).origin;

export const isEnteProductionEndpoint = async () =>
    normalizedOrigin(await apiOrigin()) ===
    normalizedOrigin(ENTE_PRODUCTION_API_ORIGIN);

export const effectiveLockerFileLimit = (
    lockerFileLimit: number,
    isProductionEndpoint: boolean,
) => {
    const normalizedLimit = Math.max(lockerFileLimit, 1);
    return !isProductionEndpoint && normalizedLimit < LOCKER_FILE_LIMIT_PAID
        ? LOCKER_FILE_LIMIT_PAID
        : normalizedLimit;
};

export interface LockerUploadLimitState {
    usage: number;
    storageLimit: number;
    fileCount: number;
    lockerFileLimit: number;
    isPartOfFamily: boolean;
    lockerFamilyFileCount?: number;
}

export interface LockerUploadAllowance {
    maxFileCount: number;
    currentFileCount: number;
    remainingFileCount: number;
    freeStorage: number;
}

export type LockerUploadPreflightFailureReason =
    | "fileCountLimit"
    | "fileTooLarge"
    | "storageLimit";

export interface LockerUploadPreflightFailure {
    reason: LockerUploadPreflightFailureReason;
    fileName?: string;
}

export const lockerUploadAllowance = (
    userDetails: LockerUploadLimitState,
    isProductionEndpoint: boolean,
): LockerUploadAllowance => {
    const maxFileCount = effectiveLockerFileLimit(
        userDetails.lockerFileLimit,
        isProductionEndpoint,
    );
    const currentFileCount =
        userDetails.isPartOfFamily &&
        typeof userDetails.lockerFamilyFileCount === "number"
            ? userDetails.lockerFamilyFileCount
            : userDetails.fileCount;

    return {
        maxFileCount,
        currentFileCount,
        remainingFileCount: Math.max(maxFileCount - currentFileCount, 0),
        freeStorage:
            Math.max(userDetails.storageLimit - userDetails.usage, 0) +
            LOCKER_STORAGE_BUFFER_BYTES,
    };
};

export const validateLockerUploadBatch = (
    files: File[],
    userDetails: LockerUploadLimitState | undefined,
    isProductionEndpoint: boolean,
): LockerUploadPreflightFailure | null => {
    const oversizedFile = files.find(
        (file) => file.size > LOCKER_MAX_FILE_SIZE_BYTES,
    );
    if (oversizedFile) {
        return { reason: "fileTooLarge", fileName: oversizedFile.name };
    }

    if (!userDetails) {
        return null;
    }

    const allowance = lockerUploadAllowance(userDetails, isProductionEndpoint);
    if (files.length > allowance.remainingFileCount) {
        return { reason: "fileCountLimit" };
    }

    const totalUploadSize = files.reduce((total, file) => total + file.size, 0);
    if (totalUploadSize > allowance.freeStorage) {
        return { reason: "storageLimit" };
    }

    return null;
};
