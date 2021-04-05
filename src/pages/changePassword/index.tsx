import React, { useState, useEffect, useContext } from 'react';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import { B64EncryptionResult } from 'services/uploadService';
import CryptoWorker, {
    setSessionKeys,
    generateAndSaveIntermediateKeyAttributes,
} from 'utils/crypto';
import { getActualKey } from 'utils/common/key';
import { logoutUser, setKeys, UpdatedKey } from 'services/userService';
import PasswordForm from 'components/PasswordForm';

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push('/');
        } else {
            setToken(user.token);
        }
    }, []);

    const onSubmit = async (passphrase, setFieldError) => {
        const cryptoWorker = await new CryptoWorker();
        const key: string = await getActualKey();
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
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
        const updatedKey: UpdatedKey = {
            kekSalt,
            encryptedKey: encryptedKeyAttributes.encryptedData,
            keyDecryptionNonce: encryptedKeyAttributes.nonce,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        };

        await setKeys(token, updatedKey);

        const updatedKeyAttributes = Object.assign(keyAttributes, updatedKey);
        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            updatedKeyAttributes,
            key
        );

        setSessionKeys(key);
        router.push('/gallery');
    };

    return (
        <PasswordForm
            callback={onSubmit}
            buttonText={constants.CHANGE_PASSWORD}
            back={() => router.push('/gallery')}
        />
    );
}
