import { CustomError } from '@ente/shared/error';
import { LS_KEYS, getData, setData } from '.';
import { Language } from '@ente/shared/i18n/locale';

export const getToken = () => {
    const token = getData(LS_KEYS.USER)?.token;
    if (!token) {
        throw Error(CustomError.TOKEN_MISSING);
    }
    return token;
};

export const getUserID = () => getData(LS_KEYS.USER)?.id;

export const isFirstLogin = () =>
    getData(LS_KEYS.IS_FIRST_LOGIN)?.status ?? false;

export function setIsFirstLogin(status: boolean) {
    setData(LS_KEYS.IS_FIRST_LOGIN, { status });
}

export const justSignedUp = () =>
    getData(LS_KEYS.JUST_SIGNED_UP)?.status ?? false;

export function setJustSignedUp(status: boolean) {
    setData(LS_KEYS.JUST_SIGNED_UP, { status });
}

export function getLivePhotoInfoShownCount() {
    return getData(LS_KEYS.LIVE_PHOTO_INFO_SHOWN_COUNT)?.count ?? 0;
}

export function setLivePhotoInfoShownCount(count: boolean) {
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

export function getLocalSentryUserID() {
    return getData(LS_KEYS.AnonymizedUserID)?.id;
}

export function setLocalSentryUserID(id: string) {
    setData(LS_KEYS.AnonymizedUserID, { id });
}

export function getLocalReferralSource() {
    return getData(LS_KEYS.REFERRAL_SOURCE)?.source;
}

export function setLocalReferralSource(source: string) {
    setData(LS_KEYS.REFERRAL_SOURCE, { source });
}
