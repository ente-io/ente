import React, { useState, useEffect } from 'react';
import constants from 'utils/strings/constants';
import { logoutUser, putAttributes } from 'services/userService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import { B64EncryptionResult } from 'services/uploadService';
import CryptoWorker, {
    setSessionKeys,
    generateAndSaveIntermediateKeyAttributes,
} from 'utils/crypto';
import PasswordForm from 'components/PasswordForm';
import { KeyAttributes } from 'types';

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [token, setToken] = useState<string>();
    const router = useRouter();

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        router.prefetch('/gallery');
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push('/');
        } else if (key) {
            router.push('/gallery');
        } else {
            setToken(user.token);
        }
    }, []);

    const onSubmit = async (passphrase, setFieldError) => {
        const cryptoWorker = await new CryptoWorker();
        const masterKey: string = await cryptoWorker.generateEncryptionKey();
        const recoveryKey: string = await cryptoWorker.generateEncryptionKey();
        const kekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
        let kek: KEK;
        try {
            kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);
        } catch (e) {
            setFieldError('confirm', constants.PASSWORD_GENERATION_FAILED);
            return;
        }
        const masterKeyEncryptedWithKek: B64EncryptionResult = await cryptoWorker.encryptToB64(
            masterKey,
            kek.key
        );
        const masterKeyEncryptedWithRecoveryKey: B64EncryptionResult = await cryptoWorker.encryptToB64(
            masterKey,
            recoveryKey
        );
        const recoveryKeyEncryptedWithMasterKey: B64EncryptionResult = await cryptoWorker.encryptToB64(
            recoveryKey,
            masterKey
        );

        const keyPair = await cryptoWorker.generateKeyPair();
        const encryptedKeyPairAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(
            keyPair.privateKey,
            masterKey
        );

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
        await putAttributes(token, getData(LS_KEYS.USER).name, keyAttributes);
        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            keyAttributes,
            masterKey
        );

        setSessionKeys(masterKey);
        router.push('/gallery');
    };

    return (
        <>
            <PasswordForm
                callback={onSubmit}
                buttonText={constants.SET_PASSPHRASE}
                back={logoutUser}
            />
        </>
    );
}
