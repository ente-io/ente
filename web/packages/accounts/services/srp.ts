import type { UserVerificationResponse } from "@/accounts/types/user";
import { sharedCryptoWorker } from "@/base/crypto";
import log from "@/base/log";
import { generateLoginSubKey } from "@ente/shared/crypto/helpers";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { SRP, SrpClient } from "fast-srp-hap";
import { v4 as uuidv4 } from "uuid";
import {
    completeSRPSetup,
    createSRPSession,
    startSRPSetup,
    verifySRPSession,
} from "../api/srp";
import type { SRPAttributes, SRPSetupAttributes } from "../types/srp";
import { convertBase64ToBuffer, convertBufferToBase64 } from "../utils";

const SRP_PARAMS = SRP.params["4096"];

export const configureSRP = async ({
    srpSalt,
    srpUserID,
    srpVerifier,
    loginSubKey,
}: SRPSetupAttributes) => {
    try {
        const srpConfigureInProgress = InMemoryStore.get(
            MS_KEYS.SRP_CONFIGURE_IN_PROGRESS,
        );
        if (srpConfigureInProgress) {
            throw Error("SRP configure already in progress");
        }
        InMemoryStore.set(MS_KEYS.SRP_CONFIGURE_IN_PROGRESS, true);
        const srpClient = await generateSRPClient(
            srpSalt,
            srpUserID,
            loginSubKey,
        );

        const srpA = convertBufferToBase64(srpClient.computeA());

        log.debug(() => `srp a: ${srpA}`);
        const token = getToken();
        const { setupID, srpB } = await startSRPSetup(token, {
            srpA,
            srpUserID,
            srpSalt,
            srpVerifier,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        const { srpM2 } = await completeSRPSetup(token, {
            srpM1,
            setupID,
        });

        srpClient.checkM2(convertBase64ToBuffer(srpM2));
    } catch (e) {
        log.error("Failed to configure SRP", e);
        throw e;
    } finally {
        InMemoryStore.set(MS_KEYS.SRP_CONFIGURE_IN_PROGRESS, false);
    }
};

export const generateSRPSetupAttributes = async (
    loginSubKey: string,
): Promise<SRPSetupAttributes> => {
    const cryptoWorker = await sharedCryptoWorker();

    const srpSalt = await cryptoWorker.generateSaltToDeriveKey();

    const srpUserID = uuidv4();

    const srpVerifierBuffer = SRP.computeVerifier(
        SRP_PARAMS,
        convertBase64ToBuffer(srpSalt),
        Buffer.from(srpUserID),
        convertBase64ToBuffer(loginSubKey),
    );

    const srpVerifier = convertBufferToBase64(srpVerifierBuffer);

    const result = {
        srpUserID,
        srpSalt,
        srpVerifier,
        loginSubKey,
    };

    log.debug(
        () => `SRP setup attributes generated: ${JSON.stringify(result)}`,
    );

    return result;
};

export const loginViaSRP = async (
    srpAttributes: SRPAttributes,
    kek: string,
): Promise<UserVerificationResponse> => {
    try {
        const loginSubKey = await generateLoginSubKey(kek);
        const srpClient = await generateSRPClient(
            srpAttributes.srpSalt,
            srpAttributes.srpUserID,
            loginSubKey,
        );
        const srpA = srpClient.computeA();
        const { srpB, sessionID } = await createSRPSession(
            srpAttributes.srpUserID,
            convertBufferToBase64(srpA),
        );
        srpClient.setB(convertBase64ToBuffer(srpB));

        const m1 = srpClient.computeM1();
        log.debug(() => `srp m1: ${convertBufferToBase64(m1)}`);
        const { srpM2, ...rest } = await verifySRPSession(
            sessionID,
            srpAttributes.srpUserID,
            convertBufferToBase64(m1),
        );
        log.debug(() => `srp verify session successful,srpM2: ${srpM2}`);

        srpClient.checkM2(convertBase64ToBuffer(srpM2));

        log.debug(() => `srp server verify successful`);
        return rest;
    } catch (e) {
        log.error("srp verify failed", e);
        throw e;
    }
};

// ====================
// HELPERS
// ====================

export const generateSRPClient = async (
    srpSalt: string,
    srpUserID: string,
    loginSubKey: string,
) => {
    return new Promise<SrpClient>((resolve, reject) => {
        SRP.genKey(function (err, secret1) {
            try {
                if (err) {
                    reject(err);
                }
                if (!secret1) {
                    throw Error("secret1 gen failed");
                }
                const srpClient = new SrpClient(
                    SRP_PARAMS,
                    convertBase64ToBuffer(srpSalt),
                    Buffer.from(srpUserID),
                    convertBase64ToBuffer(loginSubKey),
                    secret1,
                    false,
                );

                resolve(srpClient);
            } catch (e) {
                reject(e);
            }
        });
    });
};
