import React from 'react';

import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { logError } from 'utils/sentry';
import { CustomError } from 'utils/error';

import { ButtonProps, Input } from '@mui/material';
import { KeyAttributes, SRPAttributes, User } from 'types/user';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { t } from 'i18next';

export interface VerifyMasterPasswordFormProps {
    user: User;
    keyAttributes: KeyAttributes;
    callback: (
        key: string,
        passphrase: string,
        kek: string,
        keyAttributes: KeyAttributes
    ) => void;
    buttonText: string;
    submitButtonProps?: ButtonProps;
    getKeyAttributes?: (kek: string) => Promise<KeyAttributes>;
    srpAttributes?: SRPAttributes;
}

export default function VerifyMasterPasswordForm({
    user,
    keyAttributes,
    srpAttributes,
    callback,
    buttonText,
    submitButtonProps,
    getKeyAttributes,
}: VerifyMasterPasswordFormProps) {
    const verifyPassphrase: SingleInputFormProps['callback'] = async (
        passphrase,
        setFieldError
    ) => {
        try {
            const cryptoWorker = await ComlinkCryptoWorker.getInstance();
            let kek: string = null;
            try {
                if (srpAttributes) {
                    kek = await cryptoWorker.deriveKey(
                        passphrase,
                        srpAttributes.kekSalt,
                        srpAttributes.opsLimit,
                        srpAttributes.memLimit
                    );
                } else {
                    kek = await cryptoWorker.deriveKey(
                        passphrase,
                        keyAttributes.kekSalt,
                        keyAttributes.opsLimit,
                        keyAttributes.memLimit
                    );
                }
            } catch (e) {
                logError(e, 'failed to derive key');
                throw Error(CustomError.WEAK_DEVICE);
            }
            if (!keyAttributes) {
                keyAttributes = await getKeyAttributes(kek);
            }
            if (!keyAttributes) {
                return;
            }
            try {
                const key = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek
                );
                callback(key, passphrase, kek, keyAttributes);
            } catch (e) {
                logError(e, 'user entered a wrong password');
                throw Error(CustomError.INCORRECT_PASSWORD);
            }
        } catch (e) {
            switch (e.message) {
                case CustomError.WEAK_DEVICE:
                    setFieldError(t('WEAK_DEVICE'));
                    break;
                case CustomError.INCORRECT_PASSWORD:
                    setFieldError(t('INCORRECT_PASSPHRASE'));
                    break;
                default:
                    setFieldError(`${t('UNKNOWN_ERROR')} ${e.message}`);
            }
        }
    };

    return (
        <SingleInputForm
            callback={verifyPassphrase}
            placeholder={t('RETURN_PASSPHRASE_HINT')}
            buttonText={buttonText}
            submitButtonProps={submitButtonProps}
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
    );
}
