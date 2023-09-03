import React, { useState, useEffect, useContext } from 'react';
import { t } from 'i18next';

import { configureSRP, logoutUser, putAttributes } from 'services/userService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';
import {
    saveKeyInSessionStore,
    generateAndSaveIntermediateKeyAttributes,
    generateKeyAndSRPAttributes,
} from 'utils/crypto';
import SetPasswordForm from 'components/SetPasswordForm';
import { justSignedUp, setJustSignedUp } from 'utils/storage';
import RecoveryKey from 'components/RecoveryKey';
import { PAGES } from 'constants/pages';
import { VerticallyCentered } from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';
import { KeyAttributes, User } from 'types/user';
import FormPaper from 'components/Form/FormPaper';
import FormTitle from 'components/Form/FormPaper/Title';
import { APPS, getAppName } from 'constants/apps';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';

export default function Generate() {
    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();
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
            setUser(user);
            if (!user?.token) {
                router.push(PAGES.ROOT);
            } else if (key) {
                if (justSignedUp()) {
                    setRecoveryModalView(true);
                    setLoading(false);
                } else {
                    const appName = getAppName();
                    if (appName === APPS.AUTH) {
                        router.push(PAGES.AUTH);
                    } else {
                        router.push(PAGES.GALLERY);
                    }
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
            const { keyAttributes, masterKey, srpSetupAttributes } =
                await generateKeyAndSRPAttributes(passphrase);

            await putAttributes(token, keyAttributes);
            await configureSRP(srpSetupAttributes);
            await generateAndSaveIntermediateKeyAttributes(
                passphrase,
                keyAttributes,
                masterKey
            );
            await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, masterKey);
            setJustSignedUp(true);
            setRecoveryModalView(true);
        } catch (e) {
            logError(e, 'failed to generate password');
            setFieldError('passphrase', t('PASSWORD_GENERATION_FAILED'));
        }
    };

    return (
        <>
            {loading ? (
                <VerticallyCentered>
                    <EnteSpinner />
                </VerticallyCentered>
            ) : recoverModalView ? (
                <RecoveryKey
                    show={recoverModalView}
                    onHide={() => {
                        setRecoveryModalView(false);
                        const appName = getAppName();
                        if (appName === APPS.AUTH) {
                            router.push(PAGES.AUTH);
                        } else {
                            router.push(PAGES.GALLERY);
                        }
                    }}
                    somethingWentWrong={() => null}
                />
            ) : (
                <VerticallyCentered>
                    <FormPaper>
                        <FormTitle>{t('SET_PASSPHRASE')}</FormTitle>
                        <SetPasswordForm
                            userEmail={user?.email}
                            callback={onSubmit}
                            buttonText={t('SET_PASSPHRASE')}
                        />
                        <FormPaperFooter>
                            <LinkButton onClick={logoutUser}>
                                {t('GO_BACK')}
                            </LinkButton>
                        </FormPaperFooter>
                    </FormPaper>
                </VerticallyCentered>
            )}
        </>
    );
}
