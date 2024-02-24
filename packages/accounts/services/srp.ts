import { SRP, SrpClient } from "fast-srp-hap";

import { SRPAttributes, SRPSetupAttributes } from "../types/srp";

import { UserVerificationResponse } from "@ente/accounts/types/user";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { generateLoginSubKey } from "@ente/shared/crypto/helpers";
import { addLocalLog } from "@ente/shared/logging";
import { logError } from "@ente/shared/sentry";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { v4 as uuidv4 } from "uuid";
import {
    completeSRPSetup,
    createSRPSession,
    startSRPSetup,
    verifySRPSession,
} from "../api/srp";
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

        addLocalLog(() => `srp a: ${srpA}`);
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
        logError(e, "srp configure failed");
        throw e;
    } finally {
        InMemoryStore.set(MS_KEYS.SRP_CONFIGURE_IN_PROGRESS, false);
    }
};

export const generateSRPSetupAttributes = async (
    loginSubKey: string,
): Promise<SRPSetupAttributes> => {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();

    const srpSalt = await cryptoWorker.generateSaltToDeriveKey();

    const srpUserID = uuidv4();

    const srpVerifierBuffer = SRP.computeVerifier(
        SRP_PARAMS,
        convertBase64ToBuffer(srpSalt),
        Buffer.from(srpUserID),
        convertBase64ToBuffer(loginSubKey),
    );

    const srpVerifier = convertBufferToBase64(srpVerifierBuffer);

    addLocalLog(
        () => `SRP setup attributes generated',
        ${JSON.stringify({
            srpSalt,
            srpUserID,
            srpVerifier,
            loginSubKey,
        })}`,
    );

    return {
        srpUserID,
        srpSalt,
        srpVerifier,
        loginSubKey,
    };
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
        addLocalLog(() => `srp m1: ${convertBufferToBase64(m1)}`);
        const { srpM2, ...rest } = await verifySRPSession(
            sessionID,
            srpAttributes.srpUserID,
            convertBufferToBase64(m1),
        );
        addLocalLog(() => `srp verify session successful,srpM2: ${srpM2}`);

        srpClient.checkM2(convertBase64ToBuffer(srpM2));

        addLocalLog(() => `srp server verify successful`);
        return rest;
    } catch (e) {
        logError(e, "srp verify failed");
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
