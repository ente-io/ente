import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import billingService, { Subscription } from 'services/billingService';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { getToken } from 'utils/common/key';
import { getEndpoint } from 'utils/common/apiUtil';
import { Button } from 'react-bootstrap';
import {
    isSubscriptionActive,
    convertBytesToGBs,
    getUserSubscription,
    isOnFreePlan,
    isSubscriptionCancelled,
    isSubscribed,
} from 'utils/billingUtil';

import isElectron from 'is-electron';
import { Collection } from 'services/collectionService';
import { useRouter } from 'next/router';
import LinkButton from './pages/gallery/LinkButton';
import { downloadApp } from 'utils/common';
import { logoutUser } from 'services/userService';
import { LogoImage } from 'pages/_app';
import { SetDialogMessage } from './MessageDialog';
import EnteSpinner from './EnteSpinner';
import RecoveryKeyModal from './RecoveryKeyModal';
import TwoFactorModal from './TwoFactorModal';
import ExportModal from './ExportModal';
import { SetLoading } from 'pages/gallery';
import InProgressIcon from './icons/InProgressIcon';
import exportService from 'services/exportService';

interface Props {
    collections: Collection[];
    setDialogMessage: SetDialogMessage;
    setLoading: SetLoading,
    showPlanSelectorModal: () => void;
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
    useEffect(() => {
        const main = async () => {
            if (!isOpen) {
                return;
            }
            const usage = await billingService.getUsage();

            SetUsage(usage);
            setSubscription(getUserSubscription());
        };
        main();
    }, [isOpen]);

    function openFeedbackURL() {
        const feedbackURL: string = `${getEndpoint()}/users/feedback?token=${encodeURIComponent(getToken())}`;
        const win = window.open(feedbackURL, '_blank');
        win.focus();
    }
    function openSupportMail() {
        const a = document.createElement('a');
        a.href = 'mailto:contact@ente.io';

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
        props.showPlanSelectorModal();
    }
    return (
        <Menu
            isOpen={isOpen}
            onStateChange={(state) => setIsOpen(state.isOpen)}
            itemListElement="div"
        >
            <div style={{ display: 'flex', outline: 'none', textAlign: 'center' }}>
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
                }}
            >
                {user?.email}
            </div>
            <div style={{ flex: 1, overflow: 'auto', outline: 'none', paddingTop: '0' }}>
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
                                    subscription?.expiryTime,
                                )
                            ) : isSubscriptionCancelled(subscription) ? (
                                constants.RENEWAL_CANCELLED_SUBSCRIPTION_INFO(
                                    subscription?.expiryTime,
                                )
                            ) : (
                                constants.RENEWAL_ACTIVE_SUBSCRIPTION_INFO(
                                    subscription?.expiryTime,
                                )
                            )
                        ) : (
                            <p>{constants.SUBSCRIPTION_EXPIRED}</p>
                        )}
                        <Button
                            variant="outline-success"
                            block
                            size="sm"
                            onClick={onManageClick}
                        >
                            {isSubscribed(subscription) ?
                                constants.MANAGE :
                                constants.SUBSCRIBE}
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
                                Number(convertBytesToGBs(subscription?.storage)),
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
                    onClick={openFeedbackURL}
                >
                    {constants.REQUEST_FEATURE}
                </LinkButton>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={openSupportMail}
                >
                    {constants.SUPPORT}
                </LinkButton>
                <>
                    <RecoveryKeyModal
                        show={recoverModalView}
                        onHide={() => setRecoveryModalView(false)}
                        somethingWentWrong={() => props.setDialogMessage({
                            title: constants.RECOVER_KEY_GENERATION_FAILED,
                            close: { variant: 'danger' },
                        })}
                    />
                    <LinkButton
                        style={{ marginTop: '30px' }}
                        onClick={() => setRecoveryModalView(true)}
                    >
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
                        onClick={() => setTwoFactorModalView(true)}
                    >
                        {constants.TWO_FACTOR}
                    </LinkButton>
                </>
                <LinkButton
                    style={{ marginTop: '30px' }}
                    onClick={() => {
                        setData(LS_KEYS.SHOW_BACK_BUTTON, { value: true });
                        router.push('change-password');
                    }}
                >
                    {constants.CHANGE_PASSWORD}
                </LinkButton>
                <>
                    <ExportModal show={exportModalView} onHide={() => setExportModalView(false)} usage={usage} />
                    <LinkButton style={{ marginTop: '30px' }} onClick={exportFiles}>
                        <div style={{ display: 'flex' }}>
                            {constants.EXPORT}<div style={{ width: '20px' }} />
                            {exportService.isExportInProgress() &&
                                <InProgressIcon />
                            }
                        </div>
                    </LinkButton>
                </>
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
                    onClick={() => props.setDialogMessage({
                        title: `${constants.CONFIRM} ${constants.LOGOUT}`,
                        content: constants.LOGOUT_MESSAGE,
                        staticBackdrop: true,
                        proceed: {
                            text: constants.LOGOUT,
                            action: logoutUser,
                            variant: 'danger',
                        },
                        close: { text: constants.CANCEL },
                    })}
                >
                    {constants.LOGOUT}
                </LinkButton>
                <div
                    style={{
                        marginTop: '40px',
                        width: '100%',
                    }}
                />
            </div>
        </Menu >
    );
}
