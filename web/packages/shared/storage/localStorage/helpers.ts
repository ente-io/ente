import { LS_KEYS, getData, setData } from ".";

export const getToken = (): string => {
    const token = getData(LS_KEYS.USER)?.token;
    return token;
};

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

export function getLocalReferralSource() {
    return getData(LS_KEYS.REFERRAL_SOURCE)?.source;
}

export function setLocalReferralSource(source: string) {
    setData(LS_KEYS.REFERRAL_SOURCE, { source });
}
