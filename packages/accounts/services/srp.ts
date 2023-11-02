import { SRP, SrpClient } from 'fast-srp-hap';

import { SRPSetupAttributes } from '../types/srp';

import InMemoryStore, { MS_KEYS } from '@ente/shared/storage/InMemoryStore';
import { convertBase64ToBuffer, convertBufferToBase64 } from '../utils';
import { completeSRPSetup, startSRPSetup } from '../api/srp';

const SRP_PARAMS = SRP.params['4096'];

export const configureSRP = async ({
    srpSalt,
    srpUserID,
    srpVerifier,
    loginSubKey,
}: SRPSetupAttributes) => {
    try {
        const srpConfigureInProgress = InMemoryStore.get(
            MS_KEYS.SRP_CONFIGURE_IN_PROGRESS
        );
        if (srpConfigureInProgress) {
            throw Error('SRP configure already in progress');
        }
        InMemoryStore.set(MS_KEYS.SRP_CONFIGURE_IN_PROGRESS, true);
        const srpClient = await generateSRPClient(
            srpSalt,
            srpUserID,
            loginSubKey
        );

        const srpA = convertBufferToBase64(srpClient.computeA());

        // addLocalLog(() => `srp a: ${srpA}`);
        const { setupID, srpB } = await startSRPSetup({
            srpA,
            srpUserID,
            srpSalt,
            srpVerifier,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        const { srpM2 } = await completeSRPSetup({
            srpM1,
            setupID,
        });

        srpClient.checkM2(convertBase64ToBuffer(srpM2));
    } finally {
        // catch (e) {
        //     logError(e, 'srp configure failed');
        //     throw e;
        // }
        InMemoryStore.set(MS_KEYS.SRP_CONFIGURE_IN_PROGRESS, false);
    }
};

const generateSRPClient = async (
    srpSalt: string,
    srpUserID: string,
    loginSubKey: string
) => {
    return new Promise<SrpClient>((resolve, reject) => {
        SRP.genKey(function (err, secret1) {
            try {
                if (err) {
                    reject(err);
                }
                if (!secret1) {
                    throw Error('secret1 gen failed');
                }
                const srpClient = new SrpClient(
                    SRP_PARAMS,
                    convertBase64ToBuffer(srpSalt),
                    Buffer.from(srpUserID),
                    convertBase64ToBuffer(loginSubKey),
                    secret1,
                    false
                );

                resolve(srpClient);
            } catch (e) {
                reject(e);
            }
        });
    });
};
