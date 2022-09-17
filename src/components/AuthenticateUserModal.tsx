import React, { useContext, useEffect, useState } from 'react';

import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { AppContext } from 'pages/_app';
import { KeyAttributes, User } from 'types/user';
import VerifyMasterPasswordForm, {
    VerifyMasterPasswordFormProps,
} from 'components/VerifyMasterPasswordForm';
import { Dialog, Stack, Typography } from '@mui/material';
import { logError } from 'utils/sentry';

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
            title: constants.ERROR,
            close: { variant: 'danger' },
            content: constants.UNKNOWN_ERROR,
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
        <Dialog
            open={open}
            onClose={onClose}
            sx={{ position: 'absolute' }}
            PaperProps={{ sx: { p: 1, maxWidth: '346px' } }}>
            <Stack spacing={3} p={1.5}>
                <Typography variant="h3" px={1} py={0.5} fontWeight={'bold'}>
                    {constants.PASSWORD}
                </Typography>
                <VerifyMasterPasswordForm
                    buttonText={constants.AUTHENTICATE}
                    callback={useMasterPassword}
                    user={user}
                    keyAttributes={keyAttributes}
                />
            </Stack>
        </Dialog>
    );
}
