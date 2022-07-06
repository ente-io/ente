import { Dialog, Stack, Typography } from '@mui/material';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import React from 'react';
import CryptoWorker from 'utils/crypto';
import constants from 'utils/strings/constants';

export function PublicLinkSetPassword({
    open,
    onClose,
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    setChangePasswordView,
}) {
    const savePassword: SingleInputFormProps['callback'] = async (
        passphrase,
        setFieldError
    ) => {
        if (passphrase && passphrase.trim().length >= 1) {
            await enablePublicUrlPassword(passphrase);
            setChangePasswordView(false);
            publicShareProp.passwordEnabled = true;
        } else {
            setFieldError('can not be empty');
        }
    };

    const enablePublicUrlPassword = async (password: string) => {
        const cryptoWorker = await new CryptoWorker();
        const kekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
        const kek = await cryptoWorker.deriveInteractiveKey(password, kekSalt);

        return updatePublicShareURLHelper({
            collectionID: collection.id,
            passHash: kek.key,
            nonce: kekSalt,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        });
    };
    return (
        <Dialog
            open={open}
            onClose={onClose}
            disablePortal
            BackdropProps={{ sx: { position: 'absolute' } }}
            sx={{ position: 'absolute' }}
            PaperProps={{ sx: { p: 1 } }}>
            <Stack spacing={3} p={1.5}>
                <Typography variant="h3" px={1} py={0.5} fontWeight={'bold'}>
                    {constants.PASSWORD_LOCK}
                </Typography>
                <SingleInputForm
                    callback={savePassword}
                    placeholder={constants.RETURN_PASSPHRASE_HINT}
                    buttonText={constants.LOCK}
                    fieldType="password"
                    secondaryButtonAction={onClose}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                />
            </Stack>
        </Dialog>
    );
}
