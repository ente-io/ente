import { useState, useEffect } from 'react';
import { t } from 'i18next';

import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import {
    saveKeyInSessionStore,
    generateAndSaveIntermediateKeyAttributes,
    generateLoginSubKey,
    generateSRPClient,
    generateSRPSetupAttributes,
} from 'utils/crypto';
import { getActualKey } from 'utils/common/key';
import { startSRPSetup, updateSRPAndKeys } from 'services/userService';
import SetPasswordForm, {
    SetPasswordFormProps,
} from 'components/SetPasswordForm';
import { SESSION_KEYS } from 'utils/storage/sessionStorage';
import { PAGES } from 'constants/pages';
import { KEK, KeyAttributes, UpdatedKey, User } from 'types/user';
import LinkButton from 'components/pages/gallery/LinkButton';
import { VerticallyCentered } from 'components/Container';
import FormPaper from 'components/Form/FormPaper';
import FormPaperFooter from 'components/Form/FormPaper/Footer';
import FormPaperTitle from 'components/Form/FormPaper/Title';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { APPS, getAppName } from 'constants/apps';
import { convertBufferToBase64, convertBase64ToBuffer } from 'utils/user';
import InMemoryStore, { MS_KEYS } from 'services/InMemoryStore';

export default function ChangePassword() {
    const [token, setToken] = useState<string>();
    const router = useRouter();
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
        const appName = getAppName();
        if (appName === APPS.AUTH) {
            router.push(PAGES.AUTH);
        } else {
            router.push(PAGES.GALLERY);
        }
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
