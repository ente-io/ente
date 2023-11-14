const CHARACTERS =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

export function generateTempName(length: number, suffix: string) {
    let tempName = '';

    const charactersLength = CHARACTERS.length;
    for (let i = 0; i < length; i++) {
        tempName += CHARACTERS.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return `${tempName}-${suffix}`;
}
