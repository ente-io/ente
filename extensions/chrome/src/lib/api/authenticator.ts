/**
 * Authenticator API endpoints.
 */
import { z } from "zod";
import {
  AuthenticatorEntityDiffResponseSchema,
  AuthenticatorEntityKeySchema,
  type AuthenticatorEntityChange,
  type AuthenticatorEntityKey,
} from "../types/auth";
import { authenticatedRequest, buildUrl, HTTPError } from "./client";

/**
 * Get the authenticator entity key.
 * Returns undefined if no key exists yet (HTTP 404).
 */
export const getAuthenticatorKey =
  async (): Promise<AuthenticatorEntityKey | null> => {
    try {
      const response = await authenticatedRequest<unknown>("/authenticator/key");
      return AuthenticatorEntityKeySchema.parse(response);
    } catch (error) {
      if (error instanceof HTTPError && error.status === 404) {
        return null;
      }
      throw error;
    }
  };

/**
 * Result from authenticator entity diff.
 */
export interface AuthenticatorEntityDiffResult {
  entities: AuthenticatorEntityChange[];
  timestamp?: number;
  hasMore: boolean;
}

/**
 * Fetch authenticator entities since a given time.
 *
 * @param sinceTime - Epoch microseconds to fetch changes since
 * @param limit - Maximum number of entities to fetch
 */
export const getAuthenticatorEntityDiff = async (
  sinceTime = 0,
  limit = 2500,
): Promise<AuthenticatorEntityDiffResult> => {
  const url = buildUrl("/authenticator/entity/diff", {
    sinceTime,
    limit,
  });

  const response = await authenticatedRequest<unknown>(url);
  const parsed = AuthenticatorEntityDiffResponseSchema.parse(response);

  return {
    entities: parsed.diff,
    timestamp: parsed.timestamp,
    hasMore: parsed.diff.length >= limit,
  };
};

/**
 * Fetch all authenticator entities with pagination.
 * Handles deleted entities by removing them from the result.
 */
export const getAllAuthenticatorEntities = async (): Promise<{
  entities: Map<string, { encryptedData: string; header: string }>;
  timestamp?: number;
}> => {
  const entities = new Map<string, { encryptedData: string; header: string }>();
  let sinceTime = 0;
  let timestamp: number | undefined;

  while (true) {
    const result = await getAuthenticatorEntityDiff(sinceTime);

    if (result.timestamp) {
      timestamp = result.timestamp;
    }

    if (result.entities.length === 0) {
      break;
    }

    for (const entity of result.entities) {
      sinceTime = Math.max(sinceTime, entity.updatedAt);

      if (entity.isDeleted) {
        entities.delete(entity.id);
      } else if (entity.encryptedData && entity.header) {
        entities.set(entity.id, {
          encryptedData: entity.encryptedData,
          header: entity.header,
        });
      }
    }

    if (!result.hasMore) {
      break;
    }
  }

  return { entities, timestamp };
};
