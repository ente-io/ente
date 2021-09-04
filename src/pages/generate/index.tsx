import React, { useState, useEffect, useContext } from 'react';
import constants from 'utils/strings/constants';
import { logoutUser, putAttributes, User } from 'services/userService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import {
    SaveKeyInSessionStore,
    generateAndSaveIntermediateKeyAttributes,
    generateKeyAttributes,
} from 'utils/crypto';
import SetPasswordForm from 'components/SetPasswordForm';
import { justSignedUp, setJustSignedUp } from 'utils/storage';
import RecoveryKeyModal from 'components/RecoveryKeyModal';
import { KeyAttributes, PAGES } from 'types';
import Container from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';

export interface KEK {
    key: string;
    opsLimit: number;
    memLimit: number;
}

export default function Generate() {
    const [token, setToken] = useState<string>();
    const router = useRouter();
    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [loading, setLoading] = useState(true);
    const appContext = useContext(AppContext);
    useEffect(() => {
        const main = async () => {
            const key: string = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.ORIGINAL_KEY_ATTRIBUTES
            );
            router.prefetch(PAGES.GALLERY);
            router.prefetch(PAGES.CREDENTIALS);
            const user: User = getData(LS_KEYS.USER);
            if (!user?.token) {
                router.push(PAGES.ROOT);
            } else if (key) {
                if (justSignedUp()) {
                    setRecoveryModalView(true);
                    setLoading(false);
                } else {
                    router.push(PAGES.GALLERY);
                }
            } else if (keyAttributes?.encryptedKey) {
                router.push(PAGES.CREDENTIALS);
            } else {
                setToken(user.token);
                setLoading(false);
            }
        };
        main();
        appContext.showNavBar(true);
    }, []);

    const onSubmit = async (passphrase, setFieldError) => {
        try {
            const { keyAttributes, masterKey } = await generateKeyAttributes(
                passphrase
            );

            await putAttributes(token, keyAttributes);
            await generateAndSaveIntermediateKeyAttributes(
                passphrase,
                keyAttributes,
                masterKey
            );
            await SaveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, masterKey);
            setJustSignedUp(true);
            setRecoveryModalView(true);
        } catch (e) {
            logError(e, 'failed to generate password');
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
                        router.push(PAGES.GALLERY);
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
