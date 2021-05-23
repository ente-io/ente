import React, { useState, useEffect } from 'react';
import constants from 'utils/strings/constants';
import { logoutUser, putAttributes } from 'services/userService';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import {
    setSessionKeys,
    generateIntermediateKeyAttributes,
    generateKeyAttributes,
} from 'utils/crypto';
import SetPasswordForm from 'components/SetPasswordForm';
import { setJustSignedUp } from 'utils/storage';
import RecoveryKeyModal from 'components/RecoveryKeyModal';

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const [recoverModalView, setRecoveryModalView] = useState(false);

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
        try {
            const { keyAttributes, masterKey } = await generateKeyAttributes(
                passphrase
            );

            await putAttributes(
                token,
                getData(LS_KEYS.USER).name,
                keyAttributes
            );
            const intermediateKeyAttribute =
                await generateIntermediateKeyAttributes(
                    passphrase,
                    keyAttributes,
                    masterKey
                );
            setData(LS_KEYS.KEY_ATTRIBUTES, intermediateKeyAttribute);

            await setSessionKeys(masterKey);
            setJustSignedUp(true);
            setRecoveryModalView(true);
        } catch (e) {
            console.error(e);
            setFieldError('passphrase', constants.PASSWORD_GENERATION_FAILED);
        }
    };

    return (
        <>
            <SetPasswordForm
                callback={onSubmit}
                buttonText={constants.SET_PASSPHRASE}
                back={logoutUser}
            />
            <RecoveryKeyModal
                show={recoverModalView}
                onHide={() => {
                    setRecoveryModalView(false);
                    router.push('/gallery');
                }}
                somethingWentWrong={() => null}
            />
        </>
    );
}
