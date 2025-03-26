import { ensureOk, publicRequestHeaders } from "@/base/http";
import log from "@/base/log";
import { apiURL } from "@/base/origins";
import { ApiError, CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { HttpStatusCode } from "axios";
import type { UpdatedKey, UserVerificationResponse } from "./user";

export interface SRPAttributes {
    srpUserID: string;
    srpSalt: string;
    memLimit: number;
    opsLimit: number;
    kekSalt: string;
    isEmailMFAEnabled: boolean;
}

export interface GetSRPAttributesResponse {
    attributes: SRPAttributes;
}

export interface SRPSetupAttributes {
    srpSalt: string;
    srpVerifier: string;
    srpUserID: string;
    loginSubKey: string;
}

export interface SetupSRPRequest {
    srpUserID: string;
    srpSalt: string;
    srpVerifier: string;
    srpA: string;
}

export interface SetupSRPResponse {
    setupID: string;
    srpB: string;
}

export interface CompleteSRPSetupRequest {
    setupID: string;
    srpM1: string;
}

export interface CompleteSRPSetupResponse {
    setupID: string;
    srpM2: string;
}

export interface CreateSRPSessionResponse {
    sessionID: string;
    srpB: string;
}

export interface SRPVerificationResponse extends UserVerificationResponse {
    srpM2: string;
}

export interface UpdateSRPAndKeysRequest {
    srpM1: string;
    setupID: string;
    updatedKeyAttr: UpdatedKey;
    /**
     * If true (default), then all existing sessions for the user will be
     * invalidated.
     */
    logOutOtherDevices?: boolean;
}

export interface UpdateSRPAndKeysResponse {
    srpM2: string;
    setupID: string;
}

export const getSRPAttributes = async (
    email: string,
): Promise<SRPAttributes | null> => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/users/srp/attributes"),
            { email },
        );
        return (resp.data as GetSRPAttributesResponse).attributes;
    } catch (e) {
        log.error("failed to get SRP attributes", e);
        return null;
    }
};

export const startSRPSetup = async (
    token: string,
    setupSRPRequest: SetupSRPRequest,
): Promise<SetupSRPResponse> => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/setup"),
            setupSRPRequest,
            undefined,
            { "X-Auth-Token": token },
        );

        return resp.data as SetupSRPResponse;
    } catch (e) {
        log.error("failed to post SRP attributes", e);
        throw e;
    }
};

export const completeSRPSetup = async (
    token: string,
    completeSRPSetupRequest: CompleteSRPSetupRequest,
) => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/complete"),
            completeSRPSetupRequest,
            undefined,
            { "X-Auth-Token": token },
        );
        return resp.data as CompleteSRPSetupResponse;
    } catch (e) {
        log.error("failed to complete SRP setup", e);
        throw e;
    }
};

export const createSRPSession = async (srpUserID: string, srpA: string) => {
    const res = await fetch(await apiURL("/users/srp/create-session"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify({ srpUserID, srpA }),
    });
    ensureOk(res);
    const data = await res.json();
    // TODO: Use zod
    return data as CreateSRPSessionResponse;
};

export const verifySRPSession = async (
    sessionID: string,
    srpUserID: string,
    srpM1: string,
) => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/verify-session"),
            { sessionID, srpUserID, srpM1 },
            undefined,
        );
        return resp.data as SRPVerificationResponse;
    } catch (e) {
        log.error("verifySRPSession failed", e);
        if (
            e instanceof ApiError &&
            // eslint-disable-next-line @typescript-eslint/no-unsafe-enum-comparison
            e.httpStatusCode === HttpStatusCode.Unauthorized
        ) {
            throw Error(CustomError.INCORRECT_PASSWORD);
        } else {
            throw e;
        }
    }
};

export const updateSRPAndKeys = async (
    token: string,
    updateSRPAndKeyRequest: UpdateSRPAndKeysRequest,
): Promise<UpdateSRPAndKeysResponse> => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/update"),
            updateSRPAndKeyRequest,
            undefined,
            { "X-Auth-Token": token },
        );
        return resp.data as UpdateSRPAndKeysResponse;
    } catch (e) {
        log.error("updateSRPAndKeys failed", e);
        throw e;
    }
};
