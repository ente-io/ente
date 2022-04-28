import React, { useContext } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import { initiateEmail } from 'utils/common';
import { GalleryContext } from 'pages/gallery';
import { logoutUser } from 'services/userService';

export default function ExitSection() {
    const { setDialogMessage } = useContext(GalleryContext);

    const confirmLogout = () => {
        setDialogMessage({
            title: `${constants.CONFIRM} ${constants.LOGOUT}`,
            content: constants.LOGOUT_MESSAGE,
            staticBackdrop: true,
            proceed: {
                text: constants.LOGOUT,
                action: logoutUser,
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });
    };

    const showDeleteAccountDirections = () => {
        setDialogMessage({
            title: `${constants.DELETE_ACCOUNT}`,
            content: constants.DELETE_ACCOUNT_MESSAGE(),
            staticBackdrop: true,
            proceed: {
                text: constants.DELETE_ACCOUNT,
                action: () => {
                    initiateEmail('account-deletion@ente.io');
                },
                variant: 'danger',
            },
            close: { text: constants.CANCEL },
        });
    };

    return (
        <>
            <SidebarButton onClick={confirmLogout} hideArrow color="danger">
                {constants.LOGOUT}
            </SidebarButton>
            <SidebarButton
                onClick={showDeleteAccountDirections}
                hideArrow
                color="danger">
                {constants.DELETE_ACCOUNT}
            </SidebarButton>
        </>
    );
}
