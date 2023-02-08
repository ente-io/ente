import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
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
import AdvancedSettings from './AdvancedSettings';

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
    const [advancedSettingsView, setAdvancedSettingsView] = useState(false);

    const openAdvancedSettings = () => setAdvancedSettingsView(true);
    const closeAdvancedSettings = () => setAdvancedSettingsView(false);

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
            title: constants.ERROR,
            content: constants.RECOVER_KEY_GENERATION_FAILED,
            close: { variant: 'danger' },
        });

    return (
        <>
            {isElectron() && (
                <SidebarButton onClick={openWatchFolder}>
                    {constants.WATCH_FOLDERS}
                </SidebarButton>
            )}
            <SidebarButton onClick={openRecoveryKeyModal}>
                {constants.RECOVERY_KEY}
            </SidebarButton>
            {isInternalUser() && (
                <SpaceBetweenFlex sx={{ px: 1.5 }}>
                    {constants.CHOSE_THEME}
                    <ThemeSwitcher theme={theme} setTheme={setTheme} />
                </SpaceBetweenFlex>
            )}
            <SidebarButton onClick={openTwoFactorModal}>
                {constants.TWO_FACTOR}
            </SidebarButton>
            <SidebarButton onClick={redirectToChangePasswordPage}>
                {constants.CHANGE_PASSWORD}
            </SidebarButton>
            <SidebarButton onClick={redirectToChangeEmailPage}>
                {constants.CHANGE_EMAIL}
            </SidebarButton>
            <SidebarButton onClick={redirectToDeduplicatePage}>
                {constants.DEDUPLICATE_FILES}
            </SidebarButton>
            <SidebarButton onClick={openAdvancedSettings}>
                {constants.ADVANCED}
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

            <AdvancedSettings
                open={advancedSettingsView}
                onClose={closeAdvancedSettings}
                onRootClose={closeSidebar}
            />
        </>
    );
}
