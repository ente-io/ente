import React, { useState, useEffect } from 'react';
import constants from 'utils/strings/constants';
import { logoutUser, putAttributes } from 'services/userService';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import {
    setSessionKeys,
    generateAndSaveIntermediateKeyAttributes,
    generateKeyAttributes,
} from 'utils/crypto';
import SetPasswordForm from 'components/SetPasswordForm';
import { setJustSignedUp } from 'utils/storage';
import RecoveryKeyModal from 'components/RecoveryKeyModal';
import { KeyAttributes } from 'types';
import Container from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [loading, setLoading] = useState(false);
    useEffect(() => {
        const main = async () => {
            setLoading(true);
            const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.ORIGINAL_KEY_ATTRIBUTES,
            );
            router.prefetch('/gallery');
            const user = getData(LS_KEYS.USER);
            if (!user?.token) {
                router.push('/');
                return;
            }
            setToken(user.token);
            if (keyAttributes?.encryptedKey) {
                try {
                    await putAttributes(user.token, keyAttributes);
                } catch (e) {
                    // ignore
                }
                setData(LS_KEYS.ORIGINAL_KEY_ATTRIBUTES, null);
                setRecoveryModalView(true);
            } else if (key) {
                router.push('/gallery');
            }
            setLoading(false);
        };
        main();
    }, []);

    const onSubmit = async (passphrase, setFieldError) => {
        try {
            const { keyAttributes, masterKey } = await generateKeyAttributes(
                passphrase,
            );

            await putAttributes(token, keyAttributes);
            await generateAndSaveIntermediateKeyAttributes(
                passphrase,
                keyAttributes,
                masterKey,
            );
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
            {loading ? (
                <Container>
                    <EnteSpinner>
                        <span className="sr-only">Loading...</span>
                    </EnteSpinner>
                </Container>
            ) : recoverModalView ? (
                <RecoveryKeyModal
                    show={recoverModalView}
                    onHide={() => {
                        setRecoveryModalView(false);
                        router.push('/gallery');
                    }}
                    somethingWentWrong={() => null}
                />
            ) : (
                <SetPasswordForm
                    callback={onSubmit}
                    buttonText={constants.SET_PASSPHRASE}
                    back={logoutUser}
                />
            )}
        </>
    );
}
