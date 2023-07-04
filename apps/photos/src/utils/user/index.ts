import isElectron from 'is-electron';
import { UserDetails } from 'types/user';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import ElectronService from 'services/electron/common';
import { Buffer } from 'buffer';

export function makeID(length) {
    let result = '';
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}

export async function getSentryUserID() {
    if (isElectron()) {
        return await ElectronService.getSentryUserID();
    } else {
        let anonymizeUserID = getData(LS_KEYS.AnonymizedUserID)?.id;
        if (!anonymizeUserID) {
            anonymizeUserID = makeID(6);
            setData(LS_KEYS.AnonymizedUserID, { id: anonymizeUserID });
        }
        return anonymizeUserID;
    }
}

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

export const convertBufferToBase64 = (buffer: Buffer) => {
    return buffer.toString('base64');
};

export const convertBase64ToBuffer = (base64: string) => {
    return Buffer.from(base64, 'base64');
};
