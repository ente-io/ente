import { UserDetails } from 'types/user';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';

export function getLocalUserDetails(): UserDetails {
    return getData(LS_KEYS.USER_DETAILS)?.value;
}

export const isInternalUser = () => {
    const userEmail = getData(LS_KEYS.USER)?.email;
    if (!userEmail) return false;

    return (
        userEmail.endsWith('@ente.io') || userEmail === 'kr.anand619@gmail.com'
    );
};
