import React, { useEffect, useState } from 'react';

import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { KeyAttributes } from 'types';
import CryptoWorker, { setSessionKeys } from 'utils/crypto';
import PassPhraseForm from 'components/PassphraseForm';

export default function Credentials() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();

    useEffect(() => {
        router.prefetch('/gallery');
        const user = getData(LS_KEYS.USER);
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        if (!user?.token) {
            router.push('/');
        } else if (!keyAttributes) {
            router.push('/generate');
        } else {
            setKeyAttributes(keyAttributes);
        }
    }, []);

    const recover = async (recoveryKey: string, setFieldError) => {
        try {
            const cryptoWorker = await new CryptoWorker();
            let masterKey: string = await cryptoWorker.decryptB64(
                keyAttributes.masterKeyEncryptedWithRecoveryKey,
                keyAttributes.masterKeyDecryptionNonce,
                await cryptoWorker.fromHex(recoveryKey)
            );
            setSessionKeys(masterKey);
            router.push('/changePassword');
        } catch (e) {
            console.error(e);
            setFieldError('passphrase', constants.INCORRECT_RECOVERY_KEY);
        }
    };

    return (
        <PassPhraseForm
            callback={recover}
            fieldType="text"
            title={constants.RECOVER_ACCOUNT}
            placeholder={constants.RETURN_RECOVERY_KEY_HINT}
            buttonText={constants.RECOVER}
            alternateOption={{
                text: constants.NO_RECOVERY_KEY,
                click: () => null,
            }}
            back={() => null}
        />
    );
}
