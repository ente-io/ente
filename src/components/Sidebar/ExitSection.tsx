import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import { t } from 'i18next';

import { logoutUser } from 'services/userService';
import { AppContext } from 'pages/_app';
import DeleteAccountModal from 'components/DeleteAccountModal';

export default function ExitSection() {
    const { setDialogMessage } = useContext(AppContext);

    const [deleteAccountModalView, setDeleteAccountModalView] = useState(false);

    const closeDeleteAccountModal = () => setDeleteAccountModalView(false);
    const openDeleteAccountModal = () => setDeleteAccountModalView(true);

    const confirmLogout = () => {
        setDialogMessage({
            title: t('LOGOUT_MESSAGE'),
            proceed: {
                text: t('LOGOUT'),
                action: logoutUser,
                variant: 'critical',
            },
            close: { text: t('CANCEL') },
        });
    };

    return (
        <>
            <SidebarButton onClick={confirmLogout} color="critical">
                {t('LOGOUT')}
            </SidebarButton>
            <SidebarButton onClick={openDeleteAccountModal} color="critical">
                {t('DELETE_ACCOUNT')}
            </SidebarButton>
            <DeleteAccountModal
                open={deleteAccountModalView}
                onClose={closeDeleteAccountModal}
            />
        </>
    );
}
