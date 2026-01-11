/**
 * Sync service for fetching and decrypting authenticator codes.
 */
import {
  getAuthenticatorKey,
  getAllAuthenticatorEntities,
} from "../api/authenticator";
import {
  decryptAuthenticatorKey,
  decryptAuthenticatorEntity,
} from "../crypto";
import { sessionStorage, localStorage } from "../storage";
import type { Code } from "../types/code";
import { codeFromURIString, sortCodes } from "./code";

/**
 * Result of a sync operation.
 */
export interface SyncResult {
  codes: Code[];
  timeOffset: number;
}

/**
 * Sync authenticator codes from the server.
 *
 * @param masterKey - The user's decrypted master key
 * @returns Synced codes and time offset
 */
export const syncCodes = async (masterKey: string): Promise<SyncResult> => {
  // Get or fetch authenticator key
  let authenticatorKey = await sessionStorage.getAuthenticatorKey();

  if (!authenticatorKey) {
    const encryptedKey = await getAuthenticatorKey();
    if (!encryptedKey) {
      // User hasn't stored any codes yet
      await sessionStorage.setCodes([]);
      await sessionStorage.setTimeOffset(0);
      return { codes: [], timeOffset: 0 };
    }

    authenticatorKey = await decryptAuthenticatorKey(
      encryptedKey.encryptedKey,
      encryptedKey.header,
      masterKey,
    );
    await sessionStorage.setAuthenticatorKey(authenticatorKey);
  }

  // Fetch all entities
  const { entities, timestamp } = await getAllAuthenticatorEntities();

  // Calculate time offset
  let timeOffset = 0;
  if (timestamp) {
    // timestamp is in epoch microseconds, Date.now is milliseconds
    timeOffset = Date.now() - Math.floor(timestamp / 1e3);
  }

  // Decrypt and parse entities
  const codes: Code[] = [];
  for (const [id, entity] of entities) {
    try {
      const decrypted = await decryptAuthenticatorEntity(
        entity.encryptedData,
        entity.header,
        authenticatorKey,
      );
      const code = codeFromURIString(id, decrypted);

      // Skip trashed codes
      if (!code.codeDisplay?.trashed) {
        codes.push(code);
      }
    } catch (e) {
      console.error(`Failed to decrypt/parse entity ${id}`, e);
    }
  }

  // Sort codes
  const sortedCodes = sortCodes(codes);

  // Store in session
  await sessionStorage.setCodes(sortedCodes);
  await sessionStorage.setTimeOffset(timeOffset);
  await localStorage.setLastSyncTime(Date.now());

  return { codes: sortedCodes, timeOffset };
};

/**
 * Get cached codes from session storage.
 */
export const getCachedCodes = async (): Promise<Code[]> => {
  return sessionStorage.getCodes();
};

/**
 * Get cached time offset.
 */
export const getCachedTimeOffset = async (): Promise<number> => {
  return sessionStorage.getTimeOffset();
};

/**
 * Clear all cached data (for logout).
 */
export const clearCache = async (): Promise<void> => {
  await sessionStorage.clear();
};
