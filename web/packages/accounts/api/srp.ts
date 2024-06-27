import log from "@/next/log";
import { apiURL } from "@/next/origins";
import type {
    CompleteSRPSetupRequest,
    CompleteSRPSetupResponse,
    CreateSRPSessionResponse,
    GetSRPAttributesResponse,
    SRPAttributes,
    SRPVerificationResponse,
    SetupSRPRequest,
    SetupSRPResponse,
    UpdateSRPAndKeysRequest,
    UpdateSRPAndKeysResponse,
} from "@ente/accounts/types/srp";
import { ApiError, CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { HttpStatusCode } from "axios";

export const getSRPAttributes = async (
    email: string,
): Promise<SRPAttributes | null> => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/users/srp/attributes"),
            {
                email,
            },
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
            {
                "X-Auth-Token": token,
            },
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
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data as CompleteSRPSetupResponse;
    } catch (e) {
        log.error("failed to complete SRP setup", e);
        throw e;
    }
};

export const createSRPSession = async (srpUserID: string, srpA: string) => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/create-session"),
            {
                srpUserID,
                srpA,
            },
        );
        return resp.data as CreateSRPSessionResponse;
    } catch (e) {
        log.error("createSRPSession failed", e);
        throw e;
    }
};

export const verifySRPSession = async (
    sessionID: string,
    srpUserID: string,
    srpM1: string,
) => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/verify-session"),
            {
                sessionID,
                srpUserID,
                srpM1,
            },
            undefined,
        );
        return resp.data as SRPVerificationResponse;
    } catch (e) {
        log.error("verifySRPSession failed", e);
        if (
            e instanceof ApiError &&
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
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data as UpdateSRPAndKeysResponse;
    } catch (e) {
        log.error("updateSRPAndKeys failed", e);
        throw e;
    }
};
