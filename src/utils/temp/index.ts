const CHARACTERS =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

export function generateTempName(length: number) {
    let result = '';

    const charactersLength = CHARACTERS.length;
    for (let i = 0; i < length; i++) {
        result += CHARACTERS.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}
