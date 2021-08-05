import React, { useState, useEffect, useContext } from 'react';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { B64EncryptionResult } from 'services/upload/uploadService';
import CryptoWorker, {
    setSessionKeys,
    generateAndSaveIntermediateKeyAttributes,
} from 'utils/crypto';
import { getActualKey } from 'utils/common/key';
import { setKeys, UpdatedKey } from 'services/userService';
import SetPasswordForm from 'components/SetPasswordForm';
import { AppContext } from 'pages/_app';

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const appContext = useContext(AppContext);

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push('/');
        } else {
            setToken(user.token);
        }
        appContext.showNavBar(true);
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
        const encryptedKeyAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(key, kek.key);
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
            key,
        );

        setSessionKeys(key);
        redirectToGallery();
    };
    const redirectToGallery = () => {
        setData(LS_KEYS.SHOW_BACK_BUTTON, { value: false });
        router.push('/gallery');
    };
    return (
        <SetPasswordForm
            callback={onSubmit}
            buttonText={constants.CHANGE_PASSWORD}
            back={
                getData(LS_KEYS.SHOW_BACK_BUTTON)?.value ?
                    redirectToGallery :
                    null
            }
        />
    );
}
