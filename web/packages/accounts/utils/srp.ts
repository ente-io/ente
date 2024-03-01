import ComlinkCryptoWorker from "@ente/shared/crypto";
import { generateLoginSubKey } from "@ente/shared/crypto/helpers";
import { KeyAttributes } from "@ente/shared/user/types";
import { generateSRPSetupAttributes } from "../services/srp";
import { SRPSetupAttributes } from "../types/srp";

export async function generateKeyAndSRPAttributes(passphrase: string): Promise<{
    keyAttributes: KeyAttributes;
    masterKey: string;
    srpSetupAttributes: SRPSetupAttributes;
}> {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const masterKey = await cryptoWorker.generateEncryptionKey();
    const recoveryKey = await cryptoWorker.generateEncryptionKey();
    const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
    const kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);

    const masterKeyEncryptedWithKek = await cryptoWorker.encryptToB64(
        masterKey,
        kek.key,
    );
    const masterKeyEncryptedWithRecoveryKey = await cryptoWorker.encryptToB64(
        masterKey,
        recoveryKey,
    );
    const recoveryKeyEncryptedWithMasterKey = await cryptoWorker.encryptToB64(
        recoveryKey,
        masterKey,
    );

    const keyPair = await cryptoWorker.generateKeyPair();
    const encryptedKeyPairAttributes = await cryptoWorker.encryptToB64(
        keyPair.privateKey,
        masterKey,
    );

    const loginSubKey = await generateLoginSubKey(kek.key);

    const srpSetupAttributes = await generateSRPSetupAttributes(loginSubKey);

    const keyAttributes: KeyAttributes = {
        kekSalt,
        encryptedKey: masterKeyEncryptedWithKek.encryptedData,
        keyDecryptionNonce: masterKeyEncryptedWithKek.nonce,
        publicKey: keyPair.publicKey,
        encryptedSecretKey: encryptedKeyPairAttributes.encryptedData,
        secretKeyDecryptionNonce: encryptedKeyPairAttributes.nonce,
        opsLimit: kek.opsLimit,
        memLimit: kek.memLimit,
        masterKeyEncryptedWithRecoveryKey:
            masterKeyEncryptedWithRecoveryKey.encryptedData,
        masterKeyDecryptionNonce: masterKeyEncryptedWithRecoveryKey.nonce,
        recoveryKeyEncryptedWithMasterKey:
            recoveryKeyEncryptedWithMasterKey.encryptedData,
        recoveryKeyDecryptionNonce: recoveryKeyEncryptedWithMasterKey.nonce,
    };

    return {
        keyAttributes,
        masterKey,
        srpSetupAttributes,
    };
}
