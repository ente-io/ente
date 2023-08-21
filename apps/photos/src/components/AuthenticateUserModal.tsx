import React, { useContext, useEffect, useState } from 'react';

import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { AppContext } from 'pages/_app';
import { KeyAttributes, User } from 'types/user';
import VerifyMasterPasswordForm, {
    VerifyMasterPasswordFormProps,
} from 'components/VerifyMasterPasswordForm';
import { logError } from 'utils/sentry';
import { t } from 'i18next';
import DialogBoxV2 from './DialogBoxV2';
interface Iprops {
    open: boolean;
    onClose: () => void;
    onAuthenticate: () => void;
}

export default function AuthenticateUserModal({
    open,
    onClose,
    onAuthenticate,
}: Iprops) {
    const { setDialogMessage } = useContext(AppContext);
    const [user, setUser] = useState<User>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();

    const somethingWentWrong = () =>
        setDialogMessage({
            title: t('ERROR'),
            close: { variant: 'critical' },
            content: t('UNKNOWN_ERROR'),
        });

    useEffect(() => {
        const main = async () => {
            try {
                const user = getData(LS_KEYS.USER);
                if (!user) {
                    throw Error('User not found');
                }
                setUser(user);
                const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
                if (
                    (!user?.token && !user?.encryptedToken) ||
                    (keyAttributes && !keyAttributes.memLimit)
                ) {
                    throw Error('User not logged in');
                } else if (!keyAttributes) {
                    throw Error('Key attributes not found');
                } else {
                    setKeyAttributes(keyAttributes);
                }
            } catch (e) {
                logError(e, 'AuthenticateUserModal initialization failed');
                onClose();
                somethingWentWrong();
            }
        };
        main();
    }, []);

    const useMasterPassword: VerifyMasterPasswordFormProps['callback'] =
        async () => {
            onClose();
            onAuthenticate();
        };

    return (
        <DialogBoxV2
            open={open}
            onClose={onClose}
            sx={{ position: 'absolute' }}
            attributes={{
                title: t('PASSWORD'),
            }}>
            <VerifyMasterPasswordForm
                buttonText={t('AUTHENTICATE')}
                callback={useMasterPassword}
                user={user}
                keyAttributes={keyAttributes}
                submitButtonProps={{ sx: { mb: 0 } }}
            />
        </DialogBoxV2>
    );
}
