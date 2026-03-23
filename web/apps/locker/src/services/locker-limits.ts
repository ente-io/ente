import { apiOrigin } from "ente-base/origins";

export const LOCKER_FILE_LIMIT_FREE = 100;
export const LOCKER_FILE_LIMIT_PAID = 1000;

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
