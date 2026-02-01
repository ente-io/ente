/**
 * SRP login helpers.
 *
 * Implements the "SRP verification" flow against Ente's API endpoints.
 */
import { Buffer } from "buffer";
import { SRP, SrpClient } from "fast-srp-hap";
import type { VerificationResponse } from "@/lib/types/auth";
import type { SRPAttributes } from "@/lib/api/auth";
import { createSRPSession, verifySRPSession } from "@/lib/api/auth";
import { deriveKey, deriveSRPLoginSubKey } from "@/lib/crypto";

const b64ToBuffer = (base64: string): Buffer => Buffer.from(base64, "base64");
const bufferToB64 = (buffer: Buffer): string => buffer.toString("base64");

const generateSRPClient = async (
  srpSalt: string,
  srpUserID: string,
  loginSubKey: string,
): Promise<SrpClient> => {
  const clientKey = await SRP.genKey();
  return new SrpClient(
    SRP.params["4096"],
    b64ToBuffer(srpSalt),
    Buffer.from(srpUserID),
    b64ToBuffer(loginSubKey),
    clientKey,
    false,
  );
};

/**
 * Verify SRP for a user.
 *
 * @param srpAttributes User SRP attributes (includes salt/userID + KEK KDF params).
 * @param password User password (used to derive KEK, then the SRP "loginSubKey").
 */
export const verifySRP = async (
  srpAttributes: SRPAttributes,
  password: string,
): Promise<VerificationResponse> => {
  // Derive KEK from password.
  const kek = await deriveKey(
    password,
    srpAttributes.kekSalt,
    srpAttributes.opsLimit,
    srpAttributes.memLimit,
  );

  // Derive SRP password ("loginSubKey") from KEK.
  const loginSubKey = await deriveSRPLoginSubKey(kek);

  const srpClient = await generateSRPClient(
    srpAttributes.srpSalt,
    srpAttributes.srpUserID,
    loginSubKey,
  );

  // Send A, receive B + sessionID.
  const { sessionID, srpB } = await createSRPSession({
    srpUserID: srpAttributes.srpUserID,
    srpA: bufferToB64(srpClient.computeA() as Buffer),
  });

  srpClient.setB(b64ToBuffer(srpB));

  // Send M1, receive M2 + login response.
  const response = await verifySRPSession({
    sessionID,
    srpUserID: srpAttributes.srpUserID,
    srpM1: bufferToB64(srpClient.computeM1() as Buffer),
  });

  srpClient.checkM2(b64ToBuffer(response.srpM2));
  const { srpM2: _srpM2, ...rest } = response;
  return rest;
};
