import HTTPService from './HTTPService';
import { keyAttributes } from 'types';
import { getEndpoint } from 'utils/common/apiUtil';

const ENDPOINT = getEndpoint();

export const getOtt = (email: string) => {
    return HTTPService.get(`${ENDPOINT}/users/ott`, {
        email: email,
        client: 'web',
    });
};

export const verifyOtt = (email: string, ott: string) => {
    return HTTPService.get(`${ENDPOINT}/users/credentials`, { email, ott });
};

export const putAttributes = (
    token: string,
    name: string,
    keyAttributes: keyAttributes
) => {
    console.log('name ' + name);
    return HTTPService.put(
        `${ENDPOINT}/users/attributes`,
        { name: name, keyAttributes: keyAttributes },
        null,
        {
            'X-Auth-Token': token,
        }
    );
};
