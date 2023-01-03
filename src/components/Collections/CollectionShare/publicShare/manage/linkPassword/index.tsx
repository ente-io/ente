import { Box, Typography } from '@mui/material';
import { AppContext } from 'pages/_app';
import React, { useContext, useState } from 'react';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import constants from 'utils/strings/constants';
import { PublicLinkSetPassword } from './setPassword';
import PublicShareSwitch from '../../switch';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManageLinkPassword({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
}: Iprops) {
    const appContext = useContext(AppContext);
    const [changePasswordView, setChangePasswordView] = useState(false);

    const closeConfigurePassword = () => setChangePasswordView(false);

    const handlePasswordChangeSetting = async () => {
        if (publicShareProp.passwordEnabled) {
            await confirmDisablePublicUrlPassword();
        } else {
            setChangePasswordView(true);
        }
    };

    const confirmDisablePublicUrlPassword = async () => {
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
                variant: 'danger',
            },
        });
    };

    return (
        <>
            <Box>
                <Typography mb={0.5}>
                    {' '}
                    {constants.LINK_PASSWORD_LOCK}
                </Typography>
                <PublicShareSwitch
                    checked={!!publicShareProp?.passwordEnabled}
                    onChange={handlePasswordChangeSetting}
                />
            </Box>
            <PublicLinkSetPassword
                open={changePasswordView}
                onClose={closeConfigurePassword}
                collection={collection}
                publicShareProp={publicShareProp}
                updatePublicShareURLHelper={updatePublicShareURLHelper}
                setChangePasswordView={setChangePasswordView}
            />
        </>
    );
}
