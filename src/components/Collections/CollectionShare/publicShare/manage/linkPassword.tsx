import { Box, Typography } from '@mui/material';
import { ButtonVariant } from 'components/pages/gallery/LinkButton';
import { AppContext } from 'pages/_app';
import React, { useContext } from 'react';
import constants from 'utils/strings/constants';
import PublicShareSwitch from '../switch';
export function ManageLinkPassword({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    setChangePasswordView,
}) {
    const appContext = useContext(AppContext);

    const handlePasswordChangeSetting = async () => {
        if (publicShareProp.passwordEnabled) {
            await disablePublicUrlPassword();
        } else {
            setChangePasswordView(true);
        }
    };

    const disablePublicUrlPassword = async () => {
        appContext.setDialogMessage({
            title: constants.DISABLE_PASSWORD,
            content: constants.DISABLE_PASSWORD_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                text: constants.DISABLE,
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        disablePassword: true,
                    }),
                variant: ButtonVariant.danger,
            },
        });
    };
    return (
        <Box>
            <Typography> {constants.LINK_PASSWORD_LOCK}</Typography>
            <PublicShareSwitch
                checked={publicShareProp?.passwordEnabled}
                onChange={handlePasswordChangeSetting}
            />
        </Box>
    );
}
