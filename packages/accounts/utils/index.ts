import { generateLoginSubKey } from '@ente/shared/crypto/helpers';
import { KeyAttributes } from '@ente/shared/user/types';
import { generateSRPSetupAttributes } from '../services/srp';
import { SRPSetupAttributes } from '../types/srp';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import { PasswordStrength } from '@ente/accounts/constants';
import zxcvbn from 'zxcvbn';

export const convertBufferToBase64 = (buffer: Buffer) => {
    return buffer.toString('base64');
};

export const convertBase64ToBuffer = (base64: string) => {
    return Buffer.from(base64, 'base64');
};

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
        kek.key
    );
    const masterKeyEncryptedWithRecoveryKey = await cryptoWorker.encryptToB64(
        masterKey,
        recoveryKey
    );
    const recoveryKeyEncryptedWithMasterKey = await cryptoWorker.encryptToB64(
        recoveryKey,
        masterKey
    );

    const keyPair = await cryptoWorker.generateKeyPair();
    const encryptedKeyPairAttributes = await cryptoWorker.encryptToB64(
        keyPair.privateKey,
        masterKey
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

export function estimatePasswordStrength(password: string): PasswordStrength {
    if (!password) {
        return PasswordStrength.WEAK;
    }

    const zxcvbnResult = zxcvbn(password);
    if (zxcvbnResult.score < 2) {
        return PasswordStrength.WEAK;
    } else if (zxcvbnResult.score < 3) {
        return PasswordStrength.MODERATE;
    } else {
        return PasswordStrength.STRONG;
    }
}

export const isWeakPassword = (password: string) => {
    return estimatePasswordStrength(password) === PasswordStrength.WEAK;
};
