import React, { useContext, useEffect, useState } from 'react';

import constants from 'utils/strings/constants';
import { clearData, getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import { PAGES } from 'constants/pages';
import { SESSION_KEYS, getKey } from 'utils/storage/sessionStorage';
import CryptoWorker, {
    decryptAndStoreToken,
    generateAndSaveIntermediateKeyAttributes,
    saveKeyInSessionStore,
} from 'utils/crypto';
import { logoutUser } from 'services/userService';
import { isFirstLogin } from 'utils/storage';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';
import { eventBus, Events } from 'services/events';
import { KeyAttributes, User } from 'types/user';
import FormContainer from 'components/Form/FormContainer';
import FormPaper from 'components/Form/FormPaper';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import LinkButton from 'components/pages/gallery/LinkButton';
import { CustomError } from 'utils/error';
import isElectron from 'is-electron';
import desktopService from 'services/desktopService';
import VerticallyCentered from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import { Input } from '@mui/material';

export default function Credentials() {
    const router = useRouter();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const appContext = useContext(AppContext);
    const [user, setUser] = useState<User>();
    useEffect(() => {
        router.prefetch(PAGES.GALLERY);
        const main = async () => {
            const user = getData(LS_KEYS.USER);
            setUser(user);
            const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
            let key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
            if (!key && isElectron()) {
                key = await desktopService.getEncryptionKey();
                if (key) {
                    await saveKeyInSessionStore(
                        SESSION_KEYS.ENCRYPTION_KEY,
                        key,
                        true
                    );
                }
            }
            if (
                (!user?.token && !user?.encryptedToken) ||
                (keyAttributes && !keyAttributes.memLimit)
            ) {
                clearData();
                router.push(PAGES.ROOT);
            } else if (!keyAttributes) {
                router.push(PAGES.GENERATE);
            } else if (key) {
                router.push(PAGES.GALLERY);
            } else {
                setKeyAttributes(keyAttributes);
            }
        };
        main();
        appContext.showNavBar(true);
    }, []);

    const verifyPassphrase: SingleInputFormProps['callback'] = async (
        passphrase,
        setFieldError
    ) => {
        try {
            const cryptoWorker = await new CryptoWorker();
            let kek: string = null;
            try {
                kek = await cryptoWorker.deriveKey(
                    passphrase,
                    keyAttributes.kekSalt,
                    keyAttributes.opsLimit,
                    keyAttributes.memLimit
                );
            } catch (e) {
                logError(e, 'failed to derive key');
                throw Error(CustomError.WEAK_DEVICE);
            }
            try {
                const key: string = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek
                );

                if (isFirstLogin()) {
                    await generateAndSaveIntermediateKeyAttributes(
                        passphrase,
                        keyAttributes,
                        key
                    );
                    // TODO: not required after reseting appContext on first login
                    appContext.updateMlSearchEnabled(false);
                }
                await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, key);
                await decryptAndStoreToken(key);
                const redirectURL = appContext.redirectURL;
                appContext.setRedirectURL(null);
                router.push(redirectURL ?? PAGES.GALLERY);

                try {
                    eventBus.emit(Events.LOGIN);
                } catch (e) {
                    logError(e, 'Error in login handlers');
                }
            } catch (e) {
                logError(e, 'user entered a wrong password');
                throw Error(CustomError.INCORRECT_PASSWORD);
            }
        } catch (e) {
            switch (e.message) {
                case CustomError.WEAK_DEVICE:
                    setFieldError(constants.WEAK_DEVICE);
                    break;
                case CustomError.INCORRECT_PASSWORD:
                    setFieldError(constants.INCORRECT_PASSPHRASE);
                    break;
                default:
                    setFieldError(`${constants.UNKNOWN_ERROR} ${e.message}`);
            }
        }
    };

    const redirectToRecoverPage = () => router.push(PAGES.RECOVER);

    if (!keyAttributes) {
        return (
            <VerticallyCentered>
                <EnteSpinner />
            </VerticallyCentered>
        );
    }

    return (
        <FormContainer>
            <FormPaper style={{ minWidth: '320px' }}>
                <FormPaperTitle>{constants.PASSWORD}</FormPaperTitle>
                <SingleInputForm
                    callback={verifyPassphrase}
                    placeholder={constants.RETURN_PASSPHRASE_HINT}
                    buttonText={constants.VERIFY_PASSPHRASE}
                    hiddenPreInput={
                        <Input
                            id="email"
                            name="email"
                            autoComplete="username"
                            type="email"
                            hidden
                            value={user?.email}
                        />
                    }
                    autoComplete={'current-password'}
                    fieldType="password"
                />

                <FormPaperFooter style={{ justifyContent: 'space-between' }}>
                    <LinkButton onClick={redirectToRecoverPage}>
                        {constants.FORGOT_PASSWORD}
                    </LinkButton>
                    <LinkButton onClick={logoutUser}>
                        {constants.CHANGE_EMAIL}
                    </LinkButton>
                </FormPaperFooter>
            </FormPaper>
        </FormContainer>
    );
}
