import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
import { logoutUser } from 'services/userService';
import { AppContext } from 'pages/_app';
import DeleteAccountModal from 'components/DeleteAccountModal';

export default function ExitSection() {
    const { setDialogMessage } = useContext(AppContext);

    const [deleteAccountModalView, setDeleteAccountModalView] = useState(true);

    const closeDeleteAccountModal = () => setDeleteAccountModalView(false);
    const openDeleteAccountModal = () => setDeleteAccountModalView(true);

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

    return (
        <>
            <SidebarButton onClick={confirmLogout} color="danger">
                {constants.LOGOUT}
            </SidebarButton>
            <SidebarButton onClick={openDeleteAccountModal} color="danger">
                {constants.DELETE_ACCOUNT}
            </SidebarButton>
            <DeleteAccountModal
                open={deleteAccountModalView}
                onClose={closeDeleteAccountModal}
            />
        </>
    );
}
