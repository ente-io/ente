/**
 * API client for Ente backend.
 * Adapted from apps/auth/src/services/remote.ts.
 */
import { z } from "zod";
import type { AuthenticatorEntityKey, Code } from "./types";
import { codeFromURIString } from "./code";
import { decryptBox, decryptMetadataJSON } from "./crypto";

const DEFAULT_API_URL = "https://api.ente.io";

/**
 * Build the API URL with optional query parameters.
 */
export const buildApiUrl = (
    path: string,
    params?: Record<string, string | number>,
    customEndpoint?: string
): string => {
    const baseUrl = customEndpoint || DEFAULT_API_URL;
    const url = new URL(path, baseUrl);
    if (params) {
        Object.entries(params).forEach(([key, value]) => {
            url.searchParams.set(key, String(value));
        });
    }
    return url.toString();
};

/**
 * Make an authenticated request.
 */
const authenticatedFetch = async (
    url: string,
    token: string,
    options?: RequestInit
): Promise<Response> => {
    const response = await fetch(url, {
        ...options,
        headers: {
            ...options?.headers,
            "X-Auth-Token": token,
            "X-Client-Package": "io.ente.auth.web",
        },
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error("API Error:", response.status, errorText);
        throw new APIError(response.status, errorText);
    }

    return response;
};

/**
 * API error class.
 */
export class APIError extends Error {
    constructor(
        public status: number,
        public body: string
    ) {
        super(`API Error ${status}: ${body}`);
        this.name = "APIError";
    }
}

/**
 * Zod schema for entity diff response.
 */
const RemoteAuthenticatorEntityChange = z.object({
    id: z.string(),
    encryptedData: z.string().nullable(),
    header: z.string().nullable(),
    isDeleted: z.boolean(),
    updatedAt: z.number(),
});

const AuthenticatorEntityDiffResponse = z.object({
    diff: z.array(RemoteAuthenticatorEntityChange),
    timestamp: z.number().nullish(),
});

/**
 * Fetch the authenticator entity key from remote.
 */
export const getAuthenticatorEntityKey = async (
    token: string,
    customEndpoint?: string
): Promise<AuthenticatorEntityKey | undefined> => {
    const url = buildApiUrl("/authenticator/key", undefined, customEndpoint);

    try {
        const response = await authenticatedFetch(url, token);
        const data = await response.json();
        return data as AuthenticatorEntityKey;
    } catch (e) {
        if (e instanceof APIError && e.status === 404) {
            return undefined;
        }
        throw e;
    }
};

/**
 * Decrypt the authenticator key using the master key.
 */
const decryptAuthenticatorKey = async (
    remote: AuthenticatorEntityKey,
    masterKey: string
): Promise<string> =>
    decryptBox(
        {
            encryptedData: remote.encryptedKey,
            nonce: remote.header,
        },
        masterKey
    );

interface AuthenticatorEntity {
    id: string;
    data: unknown;
}

/**
 * Fetch and decrypt all authenticator entities.
 */
const fetchAuthenticatorEntities = async (
    token: string,
    authenticatorKey: string,
    customEndpoint?: string
): Promise<{ entities: AuthenticatorEntity[]; timeOffset: number | undefined }> => {
    const decrypt = (encryptedData: string, decryptionHeader: string) =>
        decryptMetadataJSON(
            { encryptedData, decryptionHeader },
            authenticatorKey
        );

    const encryptedEntities = new Map<
        string,
        { id: string; encryptedData: string; header: string }
    >();
    let sinceTime = 0;
    const batchSize = 2500;
    let timeOffset: number | undefined = undefined;

    while (true) {
        const url = buildApiUrl(
            "/authenticator/entity/diff",
            { sinceTime, limit: batchSize },
            customEndpoint
        );

        const response = await authenticatedFetch(url, token);
        const { diff, timestamp } = AuthenticatorEntityDiffResponse.parse(
            await response.json()
        );

        if (timestamp) {
            timeOffset = Date.now() - Math.floor(timestamp / 1e3);
        }

        if (diff.length === 0) break;

        for (const change of diff) {
            sinceTime = Math.max(sinceTime, change.updatedAt);
            if (change.isDeleted) {
                encryptedEntities.delete(change.id);
            } else {
                encryptedEntities.set(change.id, {
                    id: change.id,
                    encryptedData: change.encryptedData!,
                    header: change.header!,
                });
            }
        }
    }

    const entities = await Promise.all(
        [...encryptedEntities.values()].map(
            async ({ id, encryptedData, header }) => ({
                id,
                data: await decrypt(encryptedData, header),
            })
        )
    );

    return { entities, timeOffset };
};

/**
 * Result from fetching auth codes.
 */
export interface AuthCodesResult {
    codes: Code[];
    timeOffset: number | undefined;
}

/**
 * Fetch and decrypt all auth codes from remote.
 */
export const getAuthCodes = async (
    token: string,
    masterKey: string,
    customEndpoint?: string
): Promise<AuthCodesResult> => {
    const authenticatorEntityKey = await getAuthenticatorEntityKey(
        token,
        customEndpoint
    );

    if (!authenticatorEntityKey) {
        return { codes: [], timeOffset: undefined };
    }

    const authenticatorKey = await decryptAuthenticatorKey(
        authenticatorEntityKey,
        masterKey
    );

    const { entities, timeOffset } = await fetchAuthenticatorEntities(
        token,
        authenticatorKey,
        customEndpoint
    );

    const codes = entities
        .map((entity) => {
            try {
                return codeFromURIString(entity.id, entity.data as string);
            } catch (e) {
                console.error(`Failed to parse code ${entity.id}:`, e);
                return undefined;
            }
        })
        .filter((f): f is Code => f !== undefined)
        .filter((f) => !f.codeDisplay?.trashed)
        .sort((a, b) => {
            // Pinned codes first
            if (a.codeDisplay?.pinned && !b.codeDisplay?.pinned) return -1;
            if (!a.codeDisplay?.pinned && b.codeDisplay?.pinned) return 1;
            // Then by issuer
            return a.issuer.localeCompare(b.issuer);
        });

    return { codes, timeOffset };
};
