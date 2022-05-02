import React, { useState, useEffect } from 'react';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';
import CryptoWorker, {
    SaveKeyInSessionStore,
    generateAndSaveIntermediateKeyAttributes,
    B64EncryptionResult,
} from 'utils/crypto';
import { getActualKey } from 'utils/common/key';
import { setKeys } from 'services/userService';
import SetPasswordForm, {
    SetPasswordFormValues,
} from 'components/SetPasswordForm';
import { SESSION_KEYS } from 'utils/storage/sessionStorage';
import { PAGES } from 'constants/pages';
import { KEK, UpdatedKey } from 'types/user';
import { FormikHelpers } from 'formik';
import Container from 'components/Container';
import { CardContent, Box, Card } from '@mui/material';
import LogoImg from 'components/LogoImg';
import LinkButton from 'components/pages/gallery/LinkButton';

export default function ChangePassword() {
    const [token, setToken] = useState<string>();
    const router = useRouter();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push(PAGES.ROOT);
        } else {
            setToken(user.token);
        }
    }, []);

    const onSubmit = async (
        passphrase: string,
        setFieldError: FormikHelpers<SetPasswordFormValues>['setFieldError']
    ) => {
        const cryptoWorker = await new CryptoWorker();
        const key: string = await getActualKey();
        const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const kekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
        let kek: KEK;
        try {
            kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);
        } catch (e) {
            setFieldError('confirm', constants.PASSWORD_GENERATION_FAILED);
            return;
        }
        const encryptedKeyAttributes: B64EncryptionResult =
            await cryptoWorker.encryptToB64(key, kek.key);
        const updatedKey: UpdatedKey = {
            kekSalt,
            encryptedKey: encryptedKeyAttributes.encryptedData,
            keyDecryptionNonce: encryptedKeyAttributes.nonce,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        };

        await setKeys(token, updatedKey);

        const updatedKeyAttributes = Object.assign(keyAttributes, updatedKey);
        await generateAndSaveIntermediateKeyAttributes(
            passphrase,
            updatedKeyAttributes,
            key
        );

        await SaveKeyInSessionStore(SESSION_KEYS.ENCRYPTION_KEY, key);
        redirectToGallery();
    };

    const redirectToGallery = () => {
        setData(LS_KEYS.SHOW_BACK_BUTTON, { value: true });
        router.push(PAGES.GALLERY);
    };

    return (
        <Container>
            <Card sx={{ maxWidth: '520px' }}>
                <CardContent>
                    <Container disableGutters sx={{ pt: 3 }}>
                        <Box mb={4}>
                            <LogoImg src="/icon.svg" />
                            {constants.CHANGE_PASSWORD}
                        </Box>
                        <SetPasswordForm
                            callback={onSubmit}
                            buttonText={constants.CHANGE_PASSWORD}
                            back={
                                getData(LS_KEYS.SHOW_BACK_BUTTON)?.value
                                    ? redirectToGallery
                                    : null
                            }
                        />
                        <LinkButton sx={{ mt: 2 }} onClick={router.back}>
                            {constants.GO_BACK}
                        </LinkButton>
                    </Container>
                </CardContent>
            </Card>
        </Container>
    );
}
