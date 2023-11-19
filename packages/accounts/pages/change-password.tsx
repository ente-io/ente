import { useState, useEffect } from 'react';
import { t } from 'i18next';

import { getData, LS_KEYS, setData } from '@ente/shared/storage/localStorage';
import {
    saveKeyInSessionStore,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
} from '@ente/shared/crypto/helpers';
import {
    generateSRPClient,
    generateSRPSetupAttributes,
} from '@ente/accounts/services/srp';

import { getActualKey } from '@ente/shared/user';
import { startSRPSetup, updateSRPAndKeys } from '@ente/accounts/api/srp';
import SetPasswordForm, {
    SetPasswordFormProps,
} from '@ente/accounts/components/SetPasswordForm';
import { SESSION_KEYS } from '@ente/shared/storage/sessionStorage';
import { PAGES } from '@ente/accounts/constants/pages';
import { KEK, KeyAttributes, User } from '@ente/shared/user/types';
import { UpdatedKey } from '@ente/accounts/types/user';

import LinkButton from '@ente/shared/components/LinkButton';
import { VerticallyCentered } from '@ente/shared/components/Container';
import FormPaper from '@ente/shared/components/Form/FormPaper';
import FormPaperFooter from '@ente/shared/components/Form/FormPaper/Footer';
import FormPaperTitle from '@ente/shared/components/Form/FormPaper/Title';
import ComlinkCryptoWorker from '@ente/shared/crypto';
import { APP_HOMES } from '@ente/shared/apps/constants';
import {
    convertBufferToBase64,
    convertBase64ToBuffer,
} from '@ente/accounts/utils';
import InMemoryStore, { MS_KEYS } from '@ente/shared/storage/InMemoryStore';
import { PageProps } from '@ente/shared/apps/types';

export default function ChangePassword({ appName, router }: PageProps) {
    const [token, setToken] = useState<string>();
    const [user, setUser] = useState<User>();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        setUser(user);
        if (!user?.token) {
            InMemoryStore.set(MS_KEYS.REDIRECT_URL, PAGES.CHANGE_PASSWORD);
            router.push(PAGES.ROOT);
        } else {
            setToken(user.token);
        }
    }, []);

    const onSubmit: SetPasswordFormProps['callback'] = async (
        passphrase,
        setFieldError
    ) => {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const key = await getActualKey();
        const keyAttributes: KeyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
        let kek: KEK;
        try {
            kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);
        } catch (e) {
            setFieldError('confirm', t('PASSWORD_GENERATION_FAILED'));
            return;
        }
        const encryptedKeyAttributes = await cryptoWorker.encryptToB64(
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

        const loginSubKey = await generateLoginSubKey(kek.key);

        const { srpUserID, srpSalt, srpVerifier } =
            await generateSRPSetupAttributes(loginSubKey);

        const srpClient = await generateSRPClient(
            srpSalt,
            srpUserID,
            loginSubKey
        );

        const srpA = convertBufferToBase64(srpClient.computeA());

        const { setupID, srpB } = await startSRPSetup(token, {
            srpUserID,
            srpSalt,
            srpVerifier,
            srpA,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        await updateSRPAndKeys(token, {
            setupID,
            srpM1,
            updatedKeyAttr: updatedKey,
        });

        const updatedKeyAttributes = Object.assign(keyAttributes, updatedKey);
        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            updatedKeyAttributes,
            key
        );

        await saveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, key);
        redirectToAppHome();
    };

    const redirectToAppHome = () => {
        setData(LS_KEYS.SHOW_BACK_BUTTON, { value: true });
        router.push(APP_HOMES.get(appName));
    };

    return (
        <VerticallyCentered>
            <FormPaper>
                <FormPaperTitle>{t('CHANGE_PASSWORD')}</FormPaperTitle>
                <SetPasswordForm
                    userEmail={user?.email}
                    callback={onSubmit}
                    buttonText={t('CHANGE_PASSWORD')}
                />
                {(getData(LS_KEYS.SHOW_BACK_BUTTON)?.value ?? true) && (
                    <FormPaperFooter>
                        <LinkButton onClick={router.back}>
                            {t('GO_BACK')}
                        </LinkButton>
                    </FormPaperFooter>
                )}
            </FormPaper>
        </VerticallyCentered>
    );
}
