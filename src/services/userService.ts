import HTTPService from './HTTPService';
import { keyAttributes } from 'types';

const dev = process.env.NODE_ENV === 'development';
const API_ENDPOINT = process.env.NEXT_PUBLIC_ENTE_ENDPOINT || "https://api.staging.ente.io";
const ENDPOINT = !dev ? API_ENDPOINT : '/api'

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
