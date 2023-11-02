export const convertBufferToBase64 = (buffer: Buffer) => {
    return buffer.toString('base64');
};

export const convertBase64ToBuffer = (base64: string) => {
    return Buffer.from(base64, 'base64');
};
