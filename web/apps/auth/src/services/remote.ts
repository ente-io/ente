import log from "@/next/log";
import { apiURL } from "@/next/origins";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { ApiError, CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { getActualKey } from "@ente/shared/user";
import { HttpStatusCode } from "axios";
import { codeFromURIString, type Code } from "services/code";

export const getAuthCodes = async (): Promise<Code[]> => {
    const masterKey = await getActualKey();
    try {
        const authKeyData = await getAuthKey();
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const authenticatorKey = await cryptoWorker.decryptB64(
            authKeyData.encryptedKey,
            authKeyData.header,
            masterKey,
        );
        // always fetch all data from server for now
        const authEntity: AuthEntity[] = await getDiff(0);
        const authCodes = await Promise.all(
            authEntity
                .filter((f) => !f.isDeleted)
                .map(async (entity) => {
                    if (!entity.id) return undefined;
                    if (!entity.encryptedData) return undefined;
                    if (!entity.header) return undefined;
                    try {
                        const decryptedCode =
                            await cryptoWorker.decryptMetadata(
                                entity.encryptedData,
                                entity.header,
                                authenticatorKey,
                            );
                        return codeFromURIString(entity.id, decryptedCode);
                    } catch (e) {
                        log.error(`Failed to parse codeID ${entity.id}`, e);
                        return undefined;
                    }
                }),
        );
        // Remove undefined values
        const filteredAuthCodes = authCodes.filter((f): f is Code => !!f);
        filteredAuthCodes.sort((a, b) => {
            if (a.issuer && b.issuer) {
                return a.issuer.localeCompare(b.issuer);
            }
            if (a.issuer) {
                return -1;
            }
            if (b.issuer) {
                return 1;
            }
            return 0;
        });
        return filteredAuthCodes;
    } catch (e) {
        if (e instanceof Error && e.message != CustomError.AUTH_KEY_NOT_FOUND) {
            log.error("get authenticator entities failed", e);
        }
        throw e;
    }
};

interface AuthEntity {
    id: string;
    encryptedData: string | null;
    header: string | null;
    isDeleted: boolean;
    createdAt: number;
    updatedAt: number;
}

interface AuthKey {
    encryptedKey: string;
    header: string;
}

export const getAuthKey = async (): Promise<AuthKey> => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/authenticator/key"),
            {},
            {
                "X-Auth-Token": getToken(),
            },
        );
        return resp.data;
    } catch (e) {
        if (
            e instanceof ApiError &&
            e.httpStatusCode == HttpStatusCode.NotFound
        ) {
            throw Error(CustomError.AUTH_KEY_NOT_FOUND);
        } else {
            log.error("Get key failed", e);
            throw e;
        }
    }
};

// return a promise which resolves to list of AuthEnitity
export const getDiff = async (
    sinceTime: number,
    limit = 2500,
): Promise<AuthEntity[]> => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/authenticator/entity/diff"),
            {
                sinceTime,
                limit,
            },
            {
                "X-Auth-Token": getToken(),
            },
        );
        return resp.data.diff;
    } catch (e) {
        log.error("Get diff failed", e);
        throw e;
    }
};
