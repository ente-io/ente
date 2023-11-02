import HTTPService from '@ente/shared/network/HTTPService';
import { getEndpoint } from '@ente/shared/network/api';

import {
    CompleteSRPSetupRequest,
    CompleteSRPSetupResponse,
    GetSRPAttributesResponse,
    SRPAttributes,
    SetupSRPRequest,
    SetupSRPResponse,
} from '../types/srp';
import { getToken } from '@ente/shared/storage/localStorage/helpers';

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
        // logError(e, 'failed to get SRP attributes');
        return null;
    }
};

export const startSRPSetup = async (
    setupSRPRequest: SetupSRPRequest
): Promise<SetupSRPResponse> => {
    // try {
    const token = getToken();
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/srp/setup`,
        setupSRPRequest,
        undefined,
        {
            'X-Auth-Token': token,
        }
    );

    return resp.data as SetupSRPResponse;
    // }  catch (e) {
    //      logError(e, 'failed to post SRP attributes');
    //     throw e;
    // }
};

export const completeSRPSetup = async (
    completeSRPSetupRequest: CompleteSRPSetupRequest
) => {
    // try {
    const token = getToken();
    const resp = await HTTPService.post(
        `${ENDPOINT}/users/srp/complete`,
        completeSRPSetupRequest,
        undefined,
        {
            'X-Auth-Token': token,
        }
    );
    return resp.data as CompleteSRPSetupResponse;
    // } catch (e) {
    //     logError(e, 'failed to complete SRP setup');
    //     throw e;
    // }
};
