import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import { t } from 'i18next';

// import FixLargeThumbnails from 'components/FixLargeThumbnail';
import RecoveryKey from 'components/RecoveryKey';
import TwoFactorModal from 'components/TwoFactor/Modal';
import { PAGES } from 'constants/pages';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
// import mlIDbStorage from 'utils/storage/mlIDbStorage';
import isElectron from 'is-electron';
import WatchFolder from 'components/WatchFolder';
import { getDownloadAppMessage } from 'utils/ui';

import ThemeSwitcher from './ThemeSwitcher';
import { SpaceBetweenFlex } from 'components/Container';
import { isInternalUser } from 'utils/user';
import Preferences from './Preferences';

export default function UtilitySection({ closeSidebar }) {
    const router = useRouter();
    const {
        setDialogMessage,
        startLoading,
        watchFolderView,
        setWatchFolderView,
        theme,
        setTheme,
    } = useContext(AppContext);

    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [twoFactorModalView, setTwoFactorModalView] = useState(false);
    const [preferencesView, setPreferencesView] = useState(false);

    const openPreferencesOptions = () => setPreferencesView(true);
    const closePreferencesOptions = () => setPreferencesView(false);

    const openRecoveryKeyModal = () => setRecoveryModalView(true);
    const closeRecoveryKeyModal = () => setRecoveryModalView(false);

    const openTwoFactorModal = () => setTwoFactorModalView(true);
    const closeTwoFactorModal = () => setTwoFactorModalView(false);

    const openWatchFolder = () => {
        if (isElectron()) {
            setWatchFolderView(true);
        } else {
            setDialogMessage(getDownloadAppMessage());
        }
    };
    const closeWatchFolder = () => setWatchFolderView(false);

    const redirectToChangePasswordPage = () => {
        closeSidebar();
        router.push(PAGES.CHANGE_PASSWORD);
    };

    const redirectToChangeEmailPage = () => {
        closeSidebar();
        router.push(PAGES.CHANGE_EMAIL);
    };

    const redirectToDeduplicatePage = () => router.push(PAGES.DEDUPLICATE);

    const somethingWentWrong = () =>
        setDialogMessage({
            title: t('ERROR'),
            content: t('RECOVER_KEY_GENERATION_FAILED'),
            close: { variant: 'danger' },
        });

    return (
        <>
            {isElectron() && (
                <SidebarButton onClick={openWatchFolder}>
                    {t('WATCH_FOLDERS')}
                </SidebarButton>
            )}
            <SidebarButton onClick={openRecoveryKeyModal}>
                {t('RECOVERY_KEY')}
            </SidebarButton>
            {isInternalUser() && (
                <SpaceBetweenFlex sx={{ px: 1.5 }}>
                    {t('CHOSE_THEME')}
                    <ThemeSwitcher theme={theme} setTheme={setTheme} />
                </SpaceBetweenFlex>
            )}
            <SidebarButton onClick={openTwoFactorModal}>
                {t('TWO_FACTOR')}
            </SidebarButton>
            <SidebarButton onClick={redirectToChangePasswordPage}>
                {t('CHANGE_PASSWORD')}
            </SidebarButton>
            <SidebarButton onClick={redirectToChangeEmailPage}>
                {t('CHANGE_EMAIL')}
            </SidebarButton>
            <SidebarButton onClick={redirectToDeduplicatePage}>
                {t('DEDUPLICATE_FILES')}
            </SidebarButton>
            <SidebarButton onClick={openPreferencesOptions}>
                {t('PREFERENCES')}
            </SidebarButton>

            <RecoveryKey
                show={recoverModalView}
                onHide={closeRecoveryKeyModal}
                somethingWentWrong={somethingWentWrong}
            />
            <TwoFactorModal
                show={twoFactorModalView}
                onHide={closeTwoFactorModal}
                closeSidebar={closeSidebar}
                setLoading={startLoading}
            />
            <WatchFolder open={watchFolderView} onClose={closeWatchFolder} />
            <Preferences
                open={preferencesView}
                onClose={closePreferencesOptions}
                onRootClose={closeSidebar}
            />
        </>
    );
}
