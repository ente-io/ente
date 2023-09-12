import { Language } from 'constants/locale';
import { getData, LS_KEYS, setData } from './localStorage';

export const isFirstLogin = () =>
    getData(LS_KEYS.IS_FIRST_LOGIN)?.status ?? false;

export function setIsFirstLogin(status) {
    setData(LS_KEYS.IS_FIRST_LOGIN, { status });
}

export const justSignedUp = () =>
    getData(LS_KEYS.JUST_SIGNED_UP)?.status ?? false;

export function setJustSignedUp(status) {
    setData(LS_KEYS.JUST_SIGNED_UP, { status });
}

export function getLivePhotoInfoShownCount() {
    return getData(LS_KEYS.LIVE_PHOTO_INFO_SHOWN_COUNT)?.count ?? 0;
}

export function setLivePhotoInfoShownCount(count) {
    setData(LS_KEYS.LIVE_PHOTO_INFO_SHOWN_COUNT, { count });
}

export function getUserLocale(): Language {
    return getData(LS_KEYS.LOCALE)?.value;
}

export function getLocalMapEnabled(): boolean {
    return getData(LS_KEYS.MAP_ENABLED)?.value ?? false;
}

export function setLocalMapEnabled(value: boolean) {
    setData(LS_KEYS.MAP_ENABLED, { value });
}

export function getHasOptedOutOfCrashReports(): boolean {
    return getData(LS_KEYS.OPT_OUT_OF_CRASH_REPORTS)?.value ?? false;
}
