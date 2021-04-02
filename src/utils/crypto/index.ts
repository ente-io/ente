import { KEK } from 'pages/generate';
import { B64EncryptionResult } from 'services/uploadService';
import { KeyAttributes } from 'types';
import CryptoWorker from './cryptoWorker';

export async function generateIntermediateKey(
    passphrase,
    keyAttributes,
    key
): KeyAttributes {
    const cryptoWorker = await new CryptoWorker();
    const intermediateKekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
    const intermediateKek: KEK = await cryptoWorker.deriveIntermediateKey(
        passphrase,
        intermediateKekSalt
    );
    const encryptedKeyAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(
        key,
        intermediateKek.key
    );
    const x = {
        kekSalt: intermediateKekSalt,
        encryptedKey: encryptedKeyAttributes.encryptedData,
        keyDecryptionNonce: encryptedKeyAttributes.nonce,
        publicKey: keyAttributes.publicKey,
        encryptedSecretKey: keyAttributes.encryptedSecretKey,
        secretKeyDecryptionNonce: keyAttributes.secretKeyDecryptionNonce,
        opsLimit: intermediateKek.opsLimit,
        memLimit: intermediateKek.memLimit,
    };
    return x;
}
