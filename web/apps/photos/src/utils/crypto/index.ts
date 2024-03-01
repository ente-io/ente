import ComlinkCryptoWorker from "@ente/shared/crypto";
import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";
import { getActualKey } from "@ente/shared/user";

export async function decryptDeleteAccountChallenge(
    encryptedChallenge: string,
) {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const masterKey = await getActualKey();
    const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
    const secretKey = await cryptoWorker.decryptB64(
        keyAttributes.encryptedSecretKey,
        keyAttributes.secretKeyDecryptionNonce,
        masterKey,
    );
    const b64DecryptedChallenge = await cryptoWorker.boxSealOpen(
        encryptedChallenge,
        keyAttributes.publicKey,
        secretKey,
    );
    const utf8DecryptedChallenge = atob(b64DecryptedChallenge);
    return utf8DecryptedChallenge;
}
