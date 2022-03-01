export function getUTCMicroSecondsSinceEpoch(): number {
    const now = new Date();
    const utcMilllisecondsSinceEpoch =
        now.getTime() + now.getTimezoneOffset() * 60 * 1000;
    const utcSecondsSinceEpoch = Math.round(utcMilllisecondsSinceEpoch * 1000);
    return utcSecondsSinceEpoch;
}
