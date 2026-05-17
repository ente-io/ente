import { z } from "zod";

const compactString = (value: unknown) =>
    typeof value === "string" ? value.replaceAll(/\s/g, "") : value;

const decodeBase64URLUTF8 = (value: string) => {
    const base64 = value
        .replaceAll("-", "+")
        .replaceAll("_", "/")
        .padEnd(Math.ceil(value.length / 4) * 4, "=");
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index++) {
        bytes[index] = binary.charCodeAt(index);
    }
    return new TextDecoder().decode(bytes);
};

const base64ByteLength = (value: string) => {
    if (
        !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(
            value,
        )
    ) {
        return undefined;
    }

    try {
        return atob(value).length;
    } catch {
        return undefined;
    }
};

export const LegacyKitShareSchema = z.object({
    pv: z.literal(1),
    kv: z.literal(1),
    k: z.preprocess(compactString, z.string().min(1)),
    i: z.number().int().min(1).max(3),
    s: z.preprocess(
        compactString,
        z
            .string()
            .min(1)
            .refine((value) => base64ByteLength(value) === 32),
    ),
    c: z.preprocess(
        compactString,
        z
            .string()
            .min(1)
            .refine((value) => base64ByteLength(value) === 8),
    ),
    n: z.string().min(1),
});

export type LegacyKitShare = z.infer<typeof LegacyKitShareSchema>;

export const parseLegacyKitShare = (value: string): LegacyKitShare => {
    const trimmed = value.trim();
    const json = trimmed.startsWith("{")
        ? trimmed
        : decodeBase64URLUTF8(compactString(trimmed) as string);
    const parsed: unknown = JSON.parse(json);
    return LegacyKitShareSchema.parse(parsed);
};

export const describeShare = (share: LegacyKitShare) =>
    `${share.n} · part ${share.i}`;

export const validateLegacyKitSharePair = (
    first: LegacyKitShare,
    second: LegacyKitShare,
) => {
    if (first.k !== second.k) {
        throw new Error("These sheets are from different Legacy Kits.");
    }
    if (first.i === second.i) {
        throw new Error("Use two different sheets from the same Legacy Kit.");
    }
};
