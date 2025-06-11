// TODO: Audit this file, this can be better. e.g. do we need the Object.assign?

import { type KeyAttributes } from "ente-accounts/services/user";
import { boxSealOpenBytes, decryptBox, toB64URLSafe } from "ente-base/crypto";
import { getData, setLSUser } from "ente-shared/storage/localStorage";

export async function decryptAndStoreToken(
    keyAttributes: KeyAttributes,
    masterKey: string,
) {
    const user = getData("user");
    const { encryptedToken } = user;

    if (encryptedToken && encryptedToken.length > 0) {
        const { encryptedSecretKey, secretKeyDecryptionNonce, publicKey } =
            keyAttributes;
        const privateKey = await decryptBox(
            {
                encryptedData: encryptedSecretKey,
                nonce: secretKeyDecryptionNonce,
            },
            masterKey,
        );

        const decryptedToken = await toB64URLSafe(
            await boxSealOpenBytes(encryptedToken, { publicKey, privateKey }),
        );

        await setLSUser({
            ...user,
            token: decryptedToken,
            encryptedToken: null,
        });
    }
}
