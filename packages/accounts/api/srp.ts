import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint } from '@ente/shared/network/api';

import {
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
} from '@ente/accounts/types/srp';
import { ApiError, CustomError } from '@ente/shared/error';
import { HttpStatusCode } from 'axios';
import { logError } from '@ente/shared/sentry';

const ENDPOINT = getEndpoint();

export const getSRPAttributes = async (
    email: string
): Promise<SRPAttributes | null> => {
    try {
        const resp = await HTTPService.get(`${ENDPOINT}/users/srp/attributes`, {
            email,
        });
        return (resp.data as GetSRPAttributesResponse).attributes;
    } catch (e) {
        logError(e, 'failed to get SRP attributes');
        return null;
    }
};

export const startSRPSetup = async (
    token: string,
    setupSRPRequest: SetupSRPRequest
): Promise<SetupSRPResponse> => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/setup`,
            setupSRPRequest,
            undefined,
            {
                'X-Auth-Token': token,
            }
        );

        return resp.data as SetupSRPResponse;
    } catch (e) {
        logError(e, 'failed to post SRP attributes');
        throw e;
    }
};

export const completeSRPSetup = async (
    token: string,
    completeSRPSetupRequest: CompleteSRPSetupRequest
) => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/complete`,
            completeSRPSetupRequest,
            undefined,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data as CompleteSRPSetupResponse;
    } catch (e) {
        logError(e, 'failed to complete SRP setup');
        throw e;
    }
};

export const createSRPSession = async (srpUserID: string, srpA: string) => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/create-session`,
            {
                srpUserID,
                srpA,
            }
        );
        return resp.data as CreateSRPSessionResponse;
    } catch (e) {
        logError(e, 'createSRPSession failed');
        throw e;
    }
};

export const verifySRPSession = async (
    sessionID: string,
    srpUserID: string,
    srpM1: string
) => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/verify-session`,
            {
                sessionID,
                srpUserID,
                srpM1,
            },
            undefined
        );
        return resp.data as SRPVerificationResponse;
    } catch (e) {
        logError(e, 'verifySRPSession failed');
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
    updateSRPAndKeyRequest: UpdateSRPAndKeysRequest
): Promise<UpdateSRPAndKeysResponse> => {
    try {
        const resp = await HTTPService.post(
            `${ENDPOINT}/users/srp/update`,
            updateSRPAndKeyRequest,
            null,
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data as UpdateSRPAndKeysResponse;
    } catch (e) {
        logError(e, 'updateSRPAndKeys failed');
        throw e;
    }
};
