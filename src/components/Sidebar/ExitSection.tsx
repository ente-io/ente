import React, { useContext } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import { initiateEmail } from 'utils/common';
import { logoutUser } from 'services/userService';
import { AppContext } from 'pages/_app';

export default function ExitSection() {
    const { setDialogMessage } = useContext(AppContext);

    const confirmLogout = () => {
        setDialogMessage({
            title: constants.LOGOUT_MESSAGE,
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
            title: constants.DELETE_ACCOUNT,
            content: constants.DELETE_ACCOUNT_MESSAGE(),
            proceed: {
                text: constants.DELETE,
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
            <SidebarButton onClick={confirmLogout} color="danger">
                {constants.LOGOUT}
            </SidebarButton>
            <SidebarButton onClick={showDeleteAccountDirections} color="danger">
                {constants.DELETE_ACCOUNT}
            </SidebarButton>
        </>
    );
}
