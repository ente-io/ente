/**
 * Sync module for fetching and caching auth codes.
 */
import { getAuthCodes } from "@shared/api";
import type { Code } from "@shared/types";
import { getToken, getMasterKey, isUnlocked } from "./auth";
import { codesStorage, settingsStorage } from "./storage";

/**
 * Sync codes from remote.
 */
export const syncCodes = async (): Promise<Code[]> => {
    const token = await getToken();
    const masterKey = await getMasterKey();

    if (!token || !masterKey) {
        console.log("Cannot sync: not logged in or vault locked");
        return [];
    }

    const settings = await settingsStorage.getSettings();

    try {
        console.log("Syncing codes from remote...");
        const { codes, timeOffset } = await getAuthCodes(
            token,
            masterKey,
            settings.customApiEndpoint
        );

        // Cache the codes
        await codesStorage.setCodes(codes);

        // Store time offset for OTP generation
        if (timeOffset !== undefined) {
            await codesStorage.setTimeOffset(timeOffset);
        }

        // Update sync timestamp
        await codesStorage.setSyncTimestamp(Date.now());

        console.log(`Synced ${codes.length} codes`);
        return codes;
    } catch (e) {
        console.error("Failed to sync codes:", e);
        throw e;
    }
};

/**
 * Get cached codes, syncing if necessary.
 */
export const getCodes = async (forceSync = false): Promise<Code[]> => {
    if (!(await isUnlocked())) {
        return [];
    }

    // Check if we need to sync
    const lastSync = await codesStorage.getSyncTimestamp();
    const settings = await settingsStorage.getSettings();
    const syncIntervalMs = settings.syncInterval * 60 * 1000;
    const needsSync =
        forceSync || !lastSync || Date.now() - lastSync > syncIntervalMs;

    if (needsSync) {
        try {
            return await syncCodes();
        } catch {
            // Fall back to cached codes if sync fails
            const cached = await codesStorage.getCodes();
            return cached || [];
        }
    }

    const cached = await codesStorage.getCodes();
    return cached || [];
};

/**
 * Get the time offset for OTP generation.
 */
export const getTimeOffset = async (): Promise<number> => {
    return codesStorage.getTimeOffset();
};
