import { apiURL } from "ente-base/origins";

export interface CreatePasteResponse {
    accessToken: string;
    expiresAt: number;
}

export interface PastePayload {
    encryptedData: string;
    decryptionHeader: string;
    encryptedPasteKey: string;
    encryptedPasteKeyNonce: string;
    kdfNonce: string;
    kdfMemLimit: number;
    kdfOpsLimit: number;
}

const parseError = async (
    response: Response,
    context: "create" | "guard" | "consume",
) => {
    if (
        (context === "consume" || context === "guard") &&
        (response.status === 410 || response.status === 404)
    ) {
        return "This paste has expired or was already opened.";
    }
    try {
        const data = (await response.json()) as { message?: string };
        if (data.message) return data.message;
    } catch {
        // no-op
    }
    return `Request failed with status ${response.status}`;
};

export const createPaste = async (payload: PastePayload) => {
    const response = await fetch(await apiURL("/paste/create"), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
    });
    if (!response.ok) {
        throw new Error(await parseError(response, "create"));
    }
    return (await response.json()) as CreatePasteResponse;
};

export const setGuard = async (accessToken: string) => {
    const response = await fetch(await apiURL("/paste/guard"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accessToken }),
    });
    if (!response.ok) {
        throw new Error(await parseError(response, "guard"));
    }
};

export const consumePaste = async (accessToken: string) => {
    const response = await fetch(await apiURL("/paste/consume"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json", "X-Paste-Consume": "1" },
        body: JSON.stringify({ accessToken }),
    });
    if (!response.ok) {
        throw new Error(await parseError(response, "consume"));
    }
    return (await response.json()) as PastePayload;
};
