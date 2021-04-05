import React, { useState, useEffect } from 'react';
import constants from 'utils/strings/constants';
import * as Yup from 'yup';
import { logoutUser, putAttributes } from 'services/userService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import { B64EncryptionResult } from 'services/uploadService';
import CryptoWorker, {
    setSessionKeys,
    generateAndSaveIntermediateKeyAttributes,
} from 'utils/crypto';
import PasswordForm from 'components/PasswordForm';

interface formValues {
    passphrase: string;
    confirm: string;
}

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [loading, setLoading] = useState(false);
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);

    useEffect(() => {
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
        const key: string = await cryptoWorker.generateMasterKey();
        const kekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
        let kek: KEK;
        try {
            kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);
        } catch (e) {
            setFieldError('confirm', constants.PASSWORD_GENERATION_FAILED);
            return;
        }
        const encryptedKeyAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(
            key,
            kek.key
        );
        const keyPair = await cryptoWorker.generateKeyPair();
        const encryptedKeyPairAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(
            keyPair.privateKey,
            key
        );

        const keyAttributes = {
            kekSalt,
            encryptedKey: encryptedKeyAttributes.encryptedData,
            keyDecryptionNonce: encryptedKeyAttributes.nonce,
            publicKey: keyPair.publicKey,
            encryptedSecretKey: encryptedKeyPairAttributes.encryptedData,
            secretKeyDecryptionNonce: encryptedKeyPairAttributes.nonce,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        };
        await putAttributes(token, getData(LS_KEYS.USER).name, keyAttributes);
        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            keyAttributes,
            key
        );

        setSessionKeys(key);
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
