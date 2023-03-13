import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import { useTranslation } from 'react-i18next';

import { logoutUser } from 'services/userService';
import { AppContext } from 'pages/_app';
import DeleteAccountModal from 'components/DeleteAccountModal';

export default function ExitSection() {
    const { t } = useTranslation();
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
                variant: 'danger',
            },
            close: { text: t('CANCEL') },
        });
    };

    return (
        <>
            <SidebarButton onClick={confirmLogout} color="danger">
                {t('LOGOUT')}
            </SidebarButton>
            <SidebarButton onClick={openDeleteAccountModal} color="danger">
                {t('DELETE_ACCOUNT')}
            </SidebarButton>
            <DeleteAccountModal
                open={deleteAccountModalView}
                onClose={closeDeleteAccountModal}
            />
        </>
    );
}
