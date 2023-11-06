import React, { useContext, useEffect, useState } from 'react';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { VerticallyCentered } from 'components/Container';
import { logError } from 'utils/sentry';
import {
    logoutUser,
    recoverTwoFactor,
    removeTwoFactor,
} from 'services/userService';
import { AppContext } from 'pages/_app';
import { PAGES } from 'constants/pages';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
import { B64EncryptionResult } from 'types/crypto';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { t } from 'i18next';
import { Trans } from 'react-i18next';
import { Link } from '@mui/material';
import { SUPPORT_EMAIL } from 'constants/urls';
import { DialogBoxAttributes } from 'types/dialogBox';
import { ApiError } from 'utils/error';
import { HttpStatusCode } from 'axios';

const bip39 = require('bip39');
// mobile client library only supports english.
bip39.setDefaultWordlist('english');

export default function Recover() {
    const router = useRouter();
    const [encryptedTwoFactorSecret, setEncryptedTwoFactorSecret] =
        useState<B64EncryptionResult>(null);
    const [sessionID, setSessionID] = useState(null);
    const appContext = useContext(AppContext);
    const [doesHaveEncryptedRecoveryKey, setDoesHaveEncryptedRecoveryKey] =
        useState(false);

    useEffect(() => {
        router.prefetch(PAGES.GALLERY);
        const user = getData(LS_KEYS.USER);
        if (!user || !user.email || !user.twoFactorSessionID) {
            router.push(PAGES.ROOT);
        } else if (
            !user.isTwoFactorEnabled &&
            (user.encryptedToken || user.token)
        ) {
            router.push(PAGES.GENERATE);
        } else {
            setSessionID(user.twoFactorSessionID);
        }
        const main = async () => {
            try {
                const resp = await recoverTwoFactor(user.twoFactorSessionID);
                setDoesHaveEncryptedRecoveryKey(!!resp.encryptedSecret);
                if (!resp.encryptedSecret) {
                    showContactSupportDialog({
                        text: t('GO_BACK'),
                        action: router.back,
                    });
                } else {
                    setEncryptedTwoFactorSecret({
                        encryptedData: resp.encryptedSecret,
                        nonce: resp.secretDecryptionNonce,
                        key: null,
                    });
                }
            } catch (e) {
                if (
                    e instanceof ApiError &&
                    e.httpStatusCode === HttpStatusCode.NotFound
                ) {
                    logoutUser();
                } else {
                    logError(e, 'two factor recovery page setup failed');
                    setDoesHaveEncryptedRecoveryKey(false);
                    showContactSupportDialog({
                        text: t('GO_BACK'),
                        action: router.back,
                    });
                }
            }
        };
        main();
    }, []);

    const recover: SingleInputFormProps['callback'] = async (
        recoveryKey: string,
        setFieldError
    ) => {
        try {
            recoveryKey = recoveryKey
                .trim()
                .split(' ')
                .map((part) => part.trim())
                .filter((part) => !!part)
                .join(' ');
            // check if user is entering mnemonic recovery key
            if (recoveryKey.indexOf(' ') > 0) {
                if (recoveryKey.split(' ').length !== 24) {
                    throw new Error('recovery code should have 24 words');
                }
                recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
            }
            const cryptoWorker = await ComlinkCryptoWorker.getInstance();
            const twoFactorSecret = await cryptoWorker.decryptB64(
                encryptedTwoFactorSecret.encryptedData,
                encryptedTwoFactorSecret.nonce,
                await cryptoWorker.fromHex(recoveryKey)
            );
            const resp = await removeTwoFactor(sessionID, twoFactorSecret);
            const { keyAttributes, encryptedToken, token, id } = resp;
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                token,
                encryptedToken,
                id,
                isTwoFactorEnabled: false,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
            router.push(PAGES.CREDENTIALS);
        } catch (e) {
            logError(e, 'two factor recovery failed');
            setFieldError(t('INCORRECT_RECOVERY_KEY'));
        }
    };

    const showContactSupportDialog = (
        dialogClose?: DialogBoxAttributes['close']
    ) => {
        appContext.setDialogMessage({
            title: t('CONTACT_SUPPORT'),
            close: dialogClose ?? {},
            content: (
                <Trans
                    i18nKey={'NO_TWO_FACTOR_RECOVERY_KEY_MESSAGE'}
                    values={{ emailID: SUPPORT_EMAIL }}
                    components={{
                        a: <Link href={`mailto:${SUPPORT_EMAIL}`} />,
                    }}
                />
            ),
        });
    };

    if (!doesHaveEncryptedRecoveryKey) {
        return <></>;
    }

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t('RECOVER_TWO_FACTOR')}</FormPaperTitle>
                <SingleInputForm
                    callback={recover}
                    fieldType="text"
                    placeholder={t('RECOVERY_KEY_HINT')}
                    buttonText={t('RECOVER')}
                    disableAutoComplete
                />
                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    <LinkButton onClick={() => showContactSupportDialog()}>
                        {t('NO_RECOVERY_KEY')}
                    </LinkButton>
                    <LinkButton onClick={router.back}>
                        {t('GO_BACK')}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </VerticallyCentered>
    );
}
