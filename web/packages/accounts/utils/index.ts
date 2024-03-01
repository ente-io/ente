import { PasswordStrength } from "@ente/accounts/constants";
import zxcvbn from "zxcvbn";

export const convertBufferToBase64 = (buffer: Buffer) => {
    return buffer.toString("base64");
};

export const convertBase64ToBuffer = (base64: string) => {
    return Buffer.from(base64, "base64");
};

export function estimatePasswordStrength(password: string): PasswordStrength {
    if (!password) {
        return PasswordStrength.WEAK;
    }

    const zxcvbnResult = zxcvbn(password);
    if (zxcvbnResult.score < 2) {
        return PasswordStrength.WEAK;
    } else if (zxcvbnResult.score < 3) {
        return PasswordStrength.MODERATE;
    } else {
        return PasswordStrength.STRONG;
    }
}

export const isWeakPassword = (password: string) => {
    return estimatePasswordStrength(password) === PasswordStrength.WEAK;
};
