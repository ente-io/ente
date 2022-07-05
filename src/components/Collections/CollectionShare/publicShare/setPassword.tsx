import { DialogContent, DialogTitle, styled } from '@mui/material';
import DialogBoxBase from 'components/DialogBox/base';
import SingleInputForm from 'components/SingleInputForm';
import React from 'react';
import CryptoWorker from 'utils/crypto';
import constants from 'utils/strings/constants';

const SetPublicLinkSetPasswordDialog = styled(DialogBoxBase)(({ theme }) => ({
    '& .MuiDialog-container': {
        justifyContent: 'flex-end',
    },
    '& .MuiDialog-paper': {
        marginRight: theme.spacing(9),
    },
}));

export function PublicLinkSetPassword({
    open,
    onClose,
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    setChangePasswordView,
}) {
    const savePassword = async (passphrase, setFieldError) => {
        if (passphrase && passphrase.trim().length >= 1) {
            await enablePublicUrlPassword(passphrase);
            setChangePasswordView(false);
            publicShareProp.passwordEnabled = true;
        } else {
            setFieldError('linkPassword', 'can not be empty');
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
        <SetPublicLinkSetPasswordDialog open={open} onClose={onClose}>
            <DialogTitle>{constants.PASSWORD_LOCK}</DialogTitle>
            <DialogContent>
                <SingleInputForm
                    callback={savePassword}
                    placeholder={constants.RETURN_PASSPHRASE_HINT}
                    buttonText={constants.LOCK}
                    fieldType="password"
                    secondaryButtonAction={onClose}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                />
            </DialogContent>
        </SetPublicLinkSetPasswordDialog>
    );
}
