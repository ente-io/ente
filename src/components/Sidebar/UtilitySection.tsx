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
import { downloadApp } from 'utils/common';
import WatchFolderModal from 'components/WatchFolder';

export default function UtilitySection({ closeSidebar }) {
    const router = useRouter();
    const { setDialogMessage, startLoading } = useContext(AppContext);

    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [twoFactorModalView, setTwoFactorModalView] = useState(false);
    const [watchFolderModalView, setWatchFolderModalView] = useState(false);
    // const [fixLargeThumbsView, setFixLargeThumbsView] = useState(false);

    const openRecoveryKeyModal = () => setRecoveryModalView(true);
    const closeRecoveryKeyModal = () => setRecoveryModalView(false);

    const openTwoFactorModalView = () => setTwoFactorModalView(true);
    const closeTwoFactorModalView = () => setTwoFactorModalView(false);

    const openWatchModalView = () => {
        if (isElectron()) {
            setWatchFolderModalView(true);
        } else {
            setDialogMessage({
                title: constants.DOWNLOAD_APP,
                content: constants.DOWNLOAD_APP_MESSAGE(),

                proceed: {
                    text: constants.DOWNLOAD,
                    action: downloadApp,
                    variant: 'accent',
                },
                close: {
                    text: constants.CLOSE,
                },
            });
        }
    };

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

    const closeWatchFolderModal = () => setWatchFolderModalView(false);
    return (
        <>
            <SidebarButton onClick={openRecoveryKeyModal}>
                {constants.RECOVERY_KEY}
            </SidebarButton>
            <SidebarButton onClick={openTwoFactorModalView}>
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
            <SidebarButton onClick={openWatchModalView}>
                {constants.WATCH_FOLDERS}
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
                onHide={closeTwoFactorModalView}
                closeSidebar={closeSidebar}
                setLoading={startLoading}
            />
            <WatchFolderModal
                open={watchFolderModalView}
                onClose={closeWatchFolderModal}
            />

            {/* <FixLargeThumbnails
                isOpen={fixLargeThumbsView}
                hide={() => setFixLargeThumbsView(false)}
                show={() => setFixLargeThumbsView(true)}
            /> */}
        </>
    );
}
