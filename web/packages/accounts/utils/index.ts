import zxcvbn from "zxcvbn";

export type PasswordStrength = "weak" | "moderate" | "strong";

export const convertBufferToBase64 = (buffer: Buffer) => {
    return buffer.toString("base64");
};

export const convertBase64ToBuffer = (base64: string) => {
    return Buffer.from(base64, "base64");
};

export function estimatePasswordStrength(password: string): PasswordStrength {
    if (!password) {
        return "weak";
    }

    const zxcvbnResult = zxcvbn(password);
    if (zxcvbnResult.score < 2) {
        return "weak";
    } else if (zxcvbnResult.score < 3) {
        return "moderate";
    } else {
        return "strong";
    }
}

export const isWeakPassword = (password: string) => {
    return estimatePasswordStrength(password) == "weak";
};
