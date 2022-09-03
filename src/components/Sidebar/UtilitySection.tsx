import React, { useContext, useState } from 'react';
import SidebarButton from './Button';
import constants from 'utils/strings/constants';
// import FixLargeThumbnails from 'components/FixLargeThumbnail';
import RecoveryKey from 'components/RecoveryKey';
import TwoFactorModal from 'components/TwoFactor/Modal';
import { PAGES } from 'constants/pages';
import { useRouter } from 'next/router';
import { AppContext } from 'pages/_app';
import isElectron from 'is-electron';
import WatchFolder from 'components/WatchFolder';
import { getDownloadAppMessage } from 'utils/ui';

export default function UtilitySection({ closeSidebar }) {
    const router = useRouter();
    const {
        setDialogMessage,
        startLoading,
        watchFolderView,
        setWatchFolderView,
    } = useContext(AppContext);

    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [twoFactorModalView, setTwoFactorModalView] = useState(false);
    // const [fixLargeThumbsView, setFixLargeThumbsView] = useState(false);

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

    // const openThumbnailCompressModal = () => setFixLargeThumbsView(true);

    const somethingWentWrong = () =>
        setDialogMessage({
            title: constants.ERROR,
            content: constants.RECOVER_KEY_GENERATION_FAILED,
            close: { variant: 'danger' },
        });

    return (
        <>
            <SidebarButton onClick={openWatchFolder}>
                {constants.WATCH_FOLDERS}
            </SidebarButton>
            <SidebarButton onClick={openRecoveryKeyModal}>
                {constants.RECOVERY_KEY}
            </SidebarButton>
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
            {/* <SidebarButton onClick={openThumbnailCompressModal}>
                {constants.COMPRESS_THUMBNAILS}
            </SidebarButton> */}

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

            {/* <FixLargeThumbnails
                isOpen={fixLargeThumbsView}
                hide={() => setFixLargeThumbsView(false)}
                show={() => setFixLargeThumbsView(true)}
            /> */}
        </>
    );
}
