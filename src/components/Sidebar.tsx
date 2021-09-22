import React, { useContext, useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { getToken } from 'utils/common/key';
import { getEndpoint } from 'utils/common/apiUtil';
import { Button } from 'react-bootstrap';
import {
    isSubscriptionActive,
    getUserSubscription,
    isOnFreePlan,
    isSubscriptionCancelled,
    isSubscribed,
    convertToHumanReadable,
} from 'utils/billingUtil';

import isElectron from 'is-electron';
import { Collection } from 'services/collectionService';
import { useRouter } from 'next/router';
import LinkButton from './pages/gallery/LinkButton';
import { downloadApp } from 'utils/common';
import { getUserDetails, logoutUser } from 'services/userService';
import { LogoImage } from 'pages/_app';
import { SetDialogMessage } from './MessageDialog';
import EnteSpinner from './EnteSpinner';
import RecoveryKeyModal from './RecoveryKeyModal';
import TwoFactorModal from './TwoFactorModal';
import ExportModal from './ExportModal';
import { GalleryContext, SetLoading } from 'pages/gallery';
import InProgressIcon from './icons/InProgressIcon';
import exportService from 'services/exportService';
import { Subscription } from 'services/billingService';
import { PAGES } from 'types';
import { ARCHIVE_SECTION } from 'components/pages/gallery/Collections';
interface Props {
    collections: Collection[];
    setDialogMessage: SetDialogMessage;
    setLoading: SetLoading;
}
export default function Sidebar(props: Props) {
    const [usage, SetUsage] = useState<string>(null);
    const [user, setUser] = useState(null);
    const [subscription, setSubscription] = useState<Subscription>(null);
    useEffect(() => {
        setUser(getData(LS_KEYS.USER));
        setSubscription(getUserSubscription());
    }, []);
    const [isOpen, setIsOpen] = useState(false);
    const [recoverModalView, setRecoveryModalView] = useState(false);
    const [twoFactorModalView, setTwoFactorModalView] = useState(false);
    const [exportModalView, setExportModalView] = useState(false);
    const galleryContext = useContext(GalleryContext);
    useEffect(() => {
        const main = async () => {
            if (!isOpen) {
                return;
            }
            const userDetails = await getUserDetails();
            setUser({ ...user, email: userDetails.email });
            SetUsage(convertToHumanReadable(userDetails.usage));
            setSubscription(userDetails.subscription);
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                email: userDetails.email,
            });
            setData(LS_KEYS.SUBSCRIPTION, userDetails.subscription);
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

    const router = useRouter();
    function onManageClick() {
        setIsOpen(false);
        galleryContext.showPlanSelectorModal();
    }
    return (
        <Menu
            isOpen={isOpen}
            onStateChange={(state) => setIsOpen(state.isOpen)}
            itemListElement="div">
            <div
                style={{
                    display: 'flex',
                    outline: 'none',
                    textAlign: 'center',
                }}>
                <LogoImage
                    style={{ height: '24px', padding: '3px' }}
                    alt="logo"
                    src="/icon.svg"
                />
            </div>
            <div
                style={{
                    outline: 'none',
                    color: 'rgb(45, 194, 98)',
                    fontSize: '16px',
                }}>
                {user?.email}
            </div>
            <div
                style={{
                    flex: 1,
                    overflow: 'auto',
                    outline: 'none',
                    paddingTop: '0',
                }}>
                <div style={{ outline: 'none' }}>
                    <div style={{ display: 'flex' }}>
                        <h5 style={{ margin: '4px 0 12px 2px' }}>
                            {constants.SUBSCRIPTION_PLAN}
                        </h5>
                    </div>
                    <div style={{ color: '#959595' }}>
                        {isSubscriptionActive(subscription) ? (
                            isOnFreePlan(subscription) ? (
                                constants.FREE_SUBSCRIPTION_INFO(
                                    subscription?.expiryTime
                                )
                            ) : isSubscriptionCancelled(subscription) ? (
                                constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                                    subscription?.expiryTime
                                )
                            ) : (
                                constants.RENEWAL_ACTIVE_SUBSCRIPTION_INFO(
                                    subscription?.expiryTime
                                )
                            )
                        ) : (
                            <p>{constants.SUBSCRIPTION_EXPIRED}</p>
                        )}
                        <Button
                            variant="outline-success"
                            block
                            size="sm"
                            onClick={onManageClick}>
                            {isSubscribed(subscription)
                                ? constants.MANAGE
                                : constants.SUBSCRIBE}
                        </Button>
                    </div>
                </div>
                <div style={{ outline: 'none', marginTop: '30px' }} />
                <div>
                    <h5 style={{ marginBottom: '12px' }}>
                        {constants.USAGE_DETAILS}
                    </h5>
                    <div style={{ color: '#959595' }}>
                        {usage ? (
                            constants.USAGE_INFO(
                                usage,
                                convertToHumanReadable(subscription?.storage)
                            )
                        ) : (
                            <div style={{ textAlign: 'center' }}>
                                <EnteSpinner
                                    style={{
                                        borderWidth: '2px',
                                        width: '20px',
                                        height: '20px',
                                    }}
                                />
                            </div>
                        )}
                    </div>
                </div>
                <div
                    style={{
                        height: '1px',
                        marginTop: '40px',
                        background: '#242424',
                        width: '100%',
                    }}
                />
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
                    <RecoveryKeyModal
                        show={recoverModalView}
                        onHide={() => setRecoveryModalView(false)}
                        somethingWentWrong={() =>
                            props.setDialogMessage({
                                title: constants.RECOVER_KEY_GENERATION_FAILED,
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
                <>
                    <ExportModal
                        show={exportModalView}
                        onHide={() => setExportModalView(false)}
                        usage={usage}
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
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => {
                        galleryContext.setActiveCollection(ARCHIVE_SECTION);
                        setIsOpen(false);
                    }}>
                    {constants.ARCHIVE}
                </LinkButton>
                <div
                    style={{
                        height: '1px',
                        marginTop: '40px',
                        background: '#242424',
                        width: '100%',
                    }}
                />
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
                            content: constants.DELETE_MESSAGE(),
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
                <div
                    style={{
                        marginTop: '40px',
                        width: '100%',
                    }}
                />
            </div>
        </Menu>
    );
}
