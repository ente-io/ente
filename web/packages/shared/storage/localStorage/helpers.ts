import { getData, setData } from ".";

export const getToken = (): string => {
    const token = getData("user")?.token;
    return token;
};

export const isFirstLogin = () => getData("isFirstLogin")?.status ?? false;

export function setIsFirstLogin(status: boolean) {
    setData("isFirstLogin", { status });
}

export const justSignedUp = () => getData("justSignedUp")?.status ?? false;

export function setJustSignedUp(status: boolean) {
    setData("justSignedUp", { status });
}

export function getLocalReferralSource() {
    return getData("referralSource")?.source;
}

export function setLocalReferralSource(source: string) {
    setData("referralSource", { source });
}
