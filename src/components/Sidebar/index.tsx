import React, { useContext, useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { LS_KEYS, setData } from 'utils/storage/localStorage';
import { getToken } from 'utils/common/key';
import { getEndpoint } from 'utils/common/apiUtil';
import { convertBytesToHumanReadable } from 'utils/billing';

import isElectron from 'is-electron';
import { Collection } from 'types/collection';
import { useRouter } from 'next/router';
import LinkButton from '../pages/gallery/LinkButton';
import { downloadApp } from 'utils/common';
import { getUserDetails, logoutUser } from 'services/userService';
import { SetDialogMessage } from '../MessageDialog';
import RecoveryKeyModal from '../RecoveryKeyModal';
import TwoFactorModal from '../TwoFactorModal';
import ExportModal from '../ExportModal';
import { GalleryContext } from 'pages/gallery';
import InProgressIcon from '../icons/InProgressIcon';
import exportService from 'services/exportService';
import { PAGES } from 'constants/pages';
import { ARCHIVE_SECTION, TRASH_SECTION } from 'constants/collection';
import FixLargeThumbnails from '../FixLargeThumbnail';
import { SetLoading } from 'types/gallery';
import { downloadAsFile } from 'utils/file';
import { getUploadLogs, logUploadInfo } from 'utils/upload';
import { Divider, Drawer, Typography } from '@mui/material';
import { default as MuiStyled } from '@mui/styled-engine';
import ThemeToggler from './ThemeToggler';
import SubscriptionDetails from './SubscriptionDetails';
import { SpaceBetweenFlex } from 'components/Container';
import { UserDetails } from 'types/user';
import { getLocalUserDetails } from 'utils/user';
interface Props {
    collections: Collection[];
    setDialogMessage: SetDialogMessage;
    setLoading: SetLoading;
}

export enum THEMES {
    LIGHT,
    DARK,
}

const DrawerSidebar = MuiStyled(Drawer)(() => ({
    '& .MuiPaper-root': {
        width: '320px',
        padding: '20px',
    },
}));

const WidderDivider = MuiStyled(Divider)(() => ({
    marginTop: '20px',
    marginBottom: '20px',
}));

export default function Sidebar(props: Props) {
    const [userDetails, setUserDetails] = useState<UserDetails>(null);
    useEffect(() => {
        setUserDetails(getLocalUserDetails());
    }, []);
    const [isOpen, setIsOpen] = useState(false);
    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [twoFactorModalView, setTwoFactorModalView] = useState(false);
    const [exportModalView, setExportModalView] = useState(false);
    const [fixLargeThumbsView, setFixLargeThumbsView] = useState(false);
    const galleryContext = useContext(GalleryContext);
    const [theme, setTheme] = useState<THEMES>(THEMES.DARK);

    useEffect(() => {
        const main = async () => {
            const userDetails = await getUserDetails();
            setUserDetails(userDetails);
            setData(LS_KEYS.USER_DETAILS, userDetails);
        };
        main();
    }, [isOpen]);

    function openFeedbackURL() {
        const feedbackURL: string = `${getEndpoint()}/users/feedback?token=${encodeURIComponent(
            getToken()
        )}`;
        const win = window.open(feedbackURL, '_blank');
        win.focus();
    }

    function initiateEmail(email: string) {
        const a = document.createElement('a');
        a.href = 'mailto:' + email;
        a.rel = 'noreferrer noopener';
        a.click();
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    function exportFiles() {
        if (isElectron()) {
            setExportModalView(true);
        } else {
            props.setDialogMessage({
                title: constants.DOWNLOAD_APP,
                content: constants.DOWNLOAD_APP_MESSAGE(),
                staticBackdrop: true,
                proceed: {
                    text: constants.DOWNLOAD,
                    action: downloadApp,
                    variant: 'success',
                },
                close: {
                    text: constants.CLOSE,
                },
            });
        }
    }

    const downloadUploadLogs = () => {
        logUploadInfo('exporting logs');
        const logs = getUploadLogs();
        const logString = logs.join('\n');
        downloadAsFile(`upload_logs_${Date.now()}.txt`, logString);
    };

    const router = useRouter();

    return (
        <DrawerSidebar
            variant="temporary"
            anchor="left"
            open={true}
            onClose={() => setIsOpen(false)}>
            <div>
                <Typography variant="h6" component={'strong'}>
                    {constants.ENTE}
                </Typography>
                <WidderDivider />
                <SpaceBetweenFlex style={{ marginBottom: '20px' }}>
                    <Typography>{userDetails?.email}</Typography>
                    <ThemeToggler theme={theme} setTheme={setTheme} />
                </SpaceBetweenFlex>
                <SubscriptionDetails userDetails={userDetails} />

                <WidderDivider />

                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => {
                        galleryContext.setActiveCollection(ARCHIVE_SECTION);
                        setIsOpen(false);
                    }}>
                    {constants.ARCHIVE}
                </LinkButton>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => {
                        galleryContext.setActiveCollection(TRASH_SECTION);
                        setIsOpen(false);
                    }}>
                    {constants.TRASH}
                </LinkButton>
                <>
                    <RecoveryKeyModal
                        show={recoverModalView}
                        onHide={() => setRecoveryModalView(false)}
                        somethingWentWrong={() =>
                            props.setDialogMessage({
                                title: constants.ERROR,
                                content:
                                    constants.RECOVER_KEY_GENERATION_FAILED,
                                close: { variant: 'danger' },
                            })
                        }
                    />
                    <LinkButton
                        style={{ marginTop: '30px' }}
                        onClick={() => setRecoveryModalView(true)}>
                        {constants.DOWNLOAD_RECOVERY_KEY}
                    </LinkButton>
                </>
                <>
                    <TwoFactorModal
                        show={twoFactorModalView}
                        onHide={() => setTwoFactorModalView(false)}
                        setDialogMessage={props.setDialogMessage}
                        closeSidebar={() => setIsOpen(false)}
                        setLoading={props.setLoading}
                    />
                    <LinkButton
                        style={{ marginTop: '30px' }}
                        onClick={() => setTwoFactorModalView(true)}>
                        {constants.TWO_FACTOR}
                    </LinkButton>
                </>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => {
                        router.push(PAGES.CHANGE_PASSWORD);
                    }}>
                    {constants.CHANGE_PASSWORD}
                </LinkButton>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => {
                        router.push(PAGES.CHANGE_EMAIL);
                    }}>
                    {constants.UPDATE_EMAIL}
                </LinkButton>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => {
                        router.push(PAGES.DEDUPLICATE);
                    }}>
                    {constants.DEDUPLICATE_FILES}
                </LinkButton>
                <Divider />
                <>
                    <FixLargeThumbnails
                        isOpen={fixLargeThumbsView}
                        hide={() => setFixLargeThumbsView(false)}
                        show={() => setFixLargeThumbsView(true)}
                    />
                    <LinkButton
                        style={{ marginTop: '30px' }}
                        onClick={() => setFixLargeThumbsView(true)}>
                        {constants.FIX_LARGE_THUMBNAILS}
                    </LinkButton>
                </>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={openFeedbackURL}>
                    {constants.REQUEST_FEATURE}
                </LinkButton>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => initiateEmail('contact@ente.io')}>
                    {constants.SUPPORT}
                </LinkButton>
                <>
                    <ExportModal
                        show={exportModalView}
                        onHide={() => setExportModalView(false)}
                        usage={convertBytesToHumanReadable(
                            userDetails?.usage ?? 0
                        )}
                    />
                    <LinkButton
                        style={{ marginTop: '30px' }}
                        onClick={exportFiles}>
                        <div style={{ display: 'flex' }}>
                            {constants.EXPORT}
                            <div style={{ width: '20px' }} />
                            {exportService.isExportInProgress() && (
                                <InProgressIcon />
                            )}
                        </div>
                    </LinkButton>
                </>
                <Divider />
                <LinkButton
                    variant="danger"
                    style={{ marginTop: '30px' }}
                    onClick={() =>
                        props.setDialogMessage({
                            title: `${constants.CONFIRM} ${constants.LOGOUT}`,
                            content: constants.LOGOUT_MESSAGE,
                            staticBackdrop: true,
                            proceed: {
                                text: constants.LOGOUT,
                                action: logoutUser,
                                variant: 'danger',
                            },
                            close: { text: constants.CANCEL },
                        })
                    }>
                    {constants.LOGOUT}
                </LinkButton>
                <LinkButton
                    variant="danger"
                    style={{ marginTop: '30px' }}
                    onClick={() =>
                        props.setDialogMessage({
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
                        })
                    }>
                    {constants.DELETE_ACCOUNT}
                </LinkButton>
                <Divider style={{ marginTop: '36px' }} />
                <div
                    style={{
                        marginTop: '40px',
                        width: '100%',
                    }}
                />
                <div
                    style={{
                        marginTop: '30px',
                        fontSize: '14px',
                        textAlign: 'center',
                        color: 'grey',
                        cursor: 'pointer',
                    }}
                    onClick={downloadUploadLogs}>
                    {constants.DOWNLOAD_UPLOAD_LOGS}
                </div>
            </div>
        </DrawerSidebar>
    );
}
