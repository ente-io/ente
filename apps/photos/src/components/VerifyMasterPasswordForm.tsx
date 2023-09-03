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
        kek: string,
        keyAttributes: KeyAttributes,
        passphrase?: string
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
            if (!keyAttributes && typeof getKeyAttributes === 'function') {
                keyAttributes = await getKeyAttributes(kek);
            }
            if (!keyAttributes) {
                throw Error("couldn't get key attributes");
            }
            try {
                const key = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek
                );
                callback(key, kek, keyAttributes, passphrase);
            } catch (e) {
                logError(e, 'user entered a wrong password');
                throw Error(CustomError.INCORRECT_PASSWORD);
            }
        } catch (e) {
            if (e.message === CustomError.TWO_FACTOR_ENABLED) {
                // two factor enabled, user has been redirected to two factor page
                return;
            }
            logError(e, 'failed to verify passphrase');
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
