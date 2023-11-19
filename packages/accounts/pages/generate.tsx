import React, { useState, useEffect } from 'react';
import { t } from 'i18next';

import { logoutUser } from '@ente/accounts/services/user';
import { putAttributes } from '@ente/accounts/api/user';
import { configureSRP } from '@ente/accounts/services/srp';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';
import { getKey, SESSION_KEYS } from '@ente/shared/storage/sessionStorage';
import {
    saveKeyInSessionStore,
    generateAndSaveIntermediateKeyAttributes,
} from '@ente/shared/crypto/helpers';
import { generateKeyAndSRPAttributes } from '@ente/accounts/utils/srp';

import SetPasswordForm from '@ente/accounts/components/SetPasswordForm';
import {
    justSignedUp,
    setJustSignedUp,
} from '@ente/shared/storage/localStorage/helpers';
import RecoveryKey from '@ente/shared/components/RecoveryKey';
import { PAGES } from '@ente/accounts/constants/pages';
import { VerticallyCentered } from '@ente/shared/components/Container';
import EnteSpinner from '@ente/shared/components/EnteSpinner';
import { logError } from '@ente/shared/sentry';
import { KeyAttributes, User } from '@ente/shared/user/types';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import FormTitle from '@ente/shared/components/Form/FormPaper/Title';
import { APP_HOMES } from '@ente/shared/apps/constants';
import FormPaperFooter from '@ente/shared/components/Form/FormPaper/Footer';
import LinkButton from '@ente/shared/components/LinkButton';
import { PageProps } from '@ente/shared/apps/types';

export default function Generate({ router, appContext, appName }: PageProps) {
    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();
    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [loading, setLoading] = useState(true);
    useEffect(() => {
        const main = async () => {
            const key: string = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            const keyAttributes: KeyAttributes = getData(
                LS_KEYS.ORIGINAL_KEY_ATTRIBUTES
            );
            const user: User = getData(LS_KEYS.USER);
            setUser(user);
            if (!user?.token) {
                router.push(PAGES.ROOT);
            } else if (key) {
                if (justSignedUp()) {
                    setRecoveryModalView(true);
                    setLoading(false);
                } else {
                    router.push(APP_HOMES.get(appName));
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
                    appContext={appContext}
                    show={recoverModalView}
                    onHide={() => {
                        setRecoveryModalView(false);
                        router.push(APP_HOMES.get(appName));
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
