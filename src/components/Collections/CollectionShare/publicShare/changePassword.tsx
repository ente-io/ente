import DialogBox from 'components/DialogBox';
import SingleInputForm from 'components/SingleInputForm';
import React from 'react';
import CryptoWorker from 'utils/crypto';
import constants from 'utils/strings/constants';
export function PublicLinkChangePassword({
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
        <DialogBox
            open={open}
            onClose={onClose}
            size="sm"
            attributes={{
                title: constants.PASSWORD_LOCK,
            }}>
            <SingleInputForm
                callback={savePassword}
                placeholder={constants.RETURN_PASSPHRASE_HINT}
                buttonText={constants.LOCK}
                fieldType="password"
            />
        </DialogBox>
    );
}
