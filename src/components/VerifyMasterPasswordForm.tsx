import React from 'react';

import constants from 'utils/strings/constants';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { logError } from 'utils/sentry';
import { CustomError } from 'utils/error';

import { Input } from '@mui/material';
import { KeyAttributes, User } from 'types/user';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';

export interface VerifyMasterPasswordFormProps {
    user: User;
    keyAttributes: KeyAttributes;
    callback: (key: string, passphrase: string) => void;
    buttonText: string;
}

export default function VerifyMasterPasswordForm({
    user,
    keyAttributes,
    callback,
    buttonText,
}: VerifyMasterPasswordFormProps) {
    const verifyPassphrase: SingleInputFormProps['callback'] = async (
        passphrase,
        setFieldError
    ) => {
        try {
            const cryptoWorker = await ComlinkCryptoWorker.getInstance();
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
                const key = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek
                );
                callback(key, passphrase);
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

    return (
        <SingleInputForm
            callback={verifyPassphrase}
            placeholder={constants.RETURN_PASSPHRASE_HINT}
            buttonText={buttonText}
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
