import HTTPService from './HTTPService';
import { keyAttributes } from 'types';

export const getOtt = (email: string) => {
    return HTTPService.get('/api/users/ott', { email })
}

export const verifyOtt = (email: string, ott: string) => {
    return HTTPService.get('/api/users/credentials', { email, ott });
}

export const putKeyAttributes = (token: string, keyAttributes: keyAttributes) => {
    return HTTPService.put('/api/users/key-attributes', keyAttributes, null, {
        'X-Auth-Token': token,
    });
}
