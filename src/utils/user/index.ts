import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';

export function makeID(length) {
    let result = '';
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for ( let i = 0; i < length; i++ ) {
        result += characters.charAt(Math.floor(Math.random() *
 charactersLength));
    }
    return result;
}

export function getUserAnonymizedID() {
    let anonymizeUserID = getData(LS_KEYS.AnonymizeUserID)?.id;
    if (!anonymizeUserID) {
        anonymizeUserID=makeID(6);
        setData(LS_KEYS.AnonymizeUserID, { id: anonymizeUserID });
    }
    return anonymizeUserID;
}
