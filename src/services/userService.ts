import HTTPService from './HTTPService';
import { keyAttributes } from 'types';
import { getEndpoint } from 'utils/common/apiUtil';

const ENDPOINT = getEndpoint();

export const getOtt = (email: string) => {
    return HTTPService.get(`${ENDPOINT}/users/ott`, { email })
}

export const verifyOtt = (email: string, ott: string) => {
    return HTTPService.get(`${ENDPOINT}/users/credentials`, { email, ott });
}

export const putKeyAttributes = (token: string, keyAttributes: keyAttributes) => {
    return HTTPService.put(`${ENDPOINT}/users/key-attributes`, keyAttributes, null, {
        'X-Auth-Token': token,
    });
}
