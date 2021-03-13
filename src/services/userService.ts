import HTTPService from './HTTPService';
import { keyAttributes } from 'types';
import { getEndpoint } from 'utils/common/apiUtil';
import { clearKeys } from 'utils/storage/sessionStorage';
import router from 'next/router';
import { clearData } from 'utils/storage/localStorage';
import localForage from 'localforage';

const ENDPOINT = getEndpoint();

export interface user {
    id: number;
    name: string;
    email: string;
}

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

export const logoutUser = async () => {
    clearKeys();
    clearData();
    localForage.clear();
    const cache = await caches.delete('thumbs');
    router.push('/');
};
