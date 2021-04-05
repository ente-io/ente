import { getData, LS_KEYS, setData } from './localStorage';

export const isFirstLogin = () =>
    getData(LS_KEYS.IS_FIRST_LOGIN)?.status ?? false;

export function setIsFirstLogin(status) {
    setData(LS_KEYS.IS_FIRST_LOGIN, { status });
}

export const justSignedUp = () =>
    getData(LS_KEYS.JUST_SIGNED_UP)?.status ?? true;

export function setJustSignedUp(status) {
    setData(LS_KEYS.JUST_SIGNED_UP, { status });
}
