import React, { useContext, useEffect, useState } from 'react';

import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { AppContext } from 'pages/_app';
import { logError } from 'utils/sentry';
import { KeyAttributes, User } from 'types/user';
import VerticallyCentered from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import VerifyMasterPasswordForm from 'components/VerifyMasterPasswordForm';
import { Dialog, Stack, Typography } from '@mui/material';

export default function AuthenticateUserModal({ open, onClose, callback }) {
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();
    const { setDialogMessage } = useContext(AppContext);
    const [user, setUser] = useState<User>();

    const somethingWentWrong = () =>
        setDialogMessage({
            title: constants.ERROR,
            close: { variant: 'danger' },
            content: constants.UNKNOWN_ERROR,
        });

    const handleClose = () => {
        onClose();
        callback(false);
    };

    useEffect(() => {
        const main = async () => {
            const user = getData(LS_KEYS.USER);
            setUser(user);
            const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);

            if (
                (!user?.token && !user?.encryptedToken) ||
                (keyAttributes && !keyAttributes.memLimit)
            ) {
                somethingWentWrong();
            } else if (!keyAttributes) {
                somethingWentWrong();
            } else {
                setKeyAttributes(keyAttributes);
            }
        };
        main();
    }, []);

    const useMasterPassword = async (success) => {
        try {
            if (!success) {
                throw Error('master password verification failed');
            }
            callback(true);
        } catch (e) {
            logError(e, 'useMasterPassword failed');
            callback(false);
        }
    };

    if (!keyAttributes) {
        return (
            <VerticallyCentered>
                <EnteSpinner />
            </VerticallyCentered>
        );
    }

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            sx={{ position: 'absolute' }}
            PaperProps={{ sx: { p: 1, maxWidth: '346px' } }}>
            <Stack spacing={3} p={1.5}>
                <Typography variant="h3" px={1} py={0.5} fontWeight={'bold'}>
                    {constants.PASSWORD}
                </Typography>
                <VerifyMasterPasswordForm
                    callback={useMasterPassword}
                    user={user}
                    keyAttributes={keyAttributes}
                />
            </Stack>
        </Dialog>
    );
}
