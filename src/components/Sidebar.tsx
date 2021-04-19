import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import { CONFIRM_ACTION } from 'components/ConfirmDialog';
import billingService, { Subscription } from 'services/billingService';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
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

import exportService from 'services/exportService';
import { file } from 'services/fileService';
import isElectron from 'is-electron';
import { collection } from 'services/collectionService';
import { useRouter } from 'next/router';
import RecoveryKeyModal from './RecoveryKeyModal';
import { justSignedUp } from 'utils/storage';
import EnteSpinner from './EnteSpinner';
import LinkButton from 'pages/gallery/components/LinkButton';

interface Props {
    files: file[];
    collections: collection[];
    setConfirmAction: any;
    somethingWentWrong: any;
    setPlanModalView;
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
    const [modalView, setModalView] = useState(justSignedUp());
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
        const feedbackURL: string =
            getEndpoint() + '/users/feedback?token=' + getToken();
        var win = window.open(feedbackURL, '_blank');
        win.focus();
    }
    function openSupportMail() {
        var a = document.createElement('a');
        a.href = 'mailto:contact@ente.io';
        a.target = '_blank';
        a.rel = 'noreferrer noopener';
        a.click();
    }
    function exportFiles() {
        if (isElectron()) {
            exportService.exportFiles(props.files, props.collections);
        } else {
            props.setConfirmAction(CONFIRM_ACTION.DOWNLOAD_APP);
        }
    }

    const router = useRouter();

    return (
        <Menu
            isOpen={isOpen}
            onStateChange={(state) => setIsOpen(state.isOpen)}
            itemListElement="div"
        >
            <div style={{ marginBottom: '12px', outline: 'none' }}>
                Hi {user?.email} !!
            </div>
            <div style={{ outline: 'none' }}>
                <h5 style={{ marginBottom: '12px' }}>
                    {constants.SUBSCRIPTION_PLAN}
                </h5>
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
                </div>
                <div
                    style={{
                        display: 'flex',
                        flexDirection: 'column',
                    }}
                >
                    {isSubscribed(subscription) ? (
                        <div style={{ marginBottom: '10px' }}>
                            <Button
                                variant="outline-secondary"
                                size="sm"
                                onClick={() => {
                                    setIsOpen(false);
                                    props.setPlanModalView(true);
                                }}
                            >
                                {constants.MANAGE}
                            </Button>
                        </div>
                    ) : (
                        <Button
                            variant="outline-success"
                            size="sm"
                            onClick={() => {
                                setIsOpen(false);
                                props.setPlanModalView(true);
                            }}
                        >
                            {constants.SUBSCRIBE}
                        </Button>
                    )}
                </div>
            </div>
            <div style={{ outline: 'none', marginTop: '30px' }}></div>
            <div>
                <h5 style={{ marginBottom: '12px' }}>
                    {constants.USAGE_DETAILS}
                </h5>
                <div style={{ color: '#959595' }}>
                    {usage ? (
                        constants.USAGE_INFO(
                            usage,
                            Math.ceil(
                                Number(convertBytesToGBs(subscription?.storage))
                            )
                        )
                    ) : (
                        <EnteSpinner />
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
            ></div>
            <LinkButton onClick={openFeedbackURL}>
                {constants.REQUEST_FEATURE}
            </LinkButton>
            <LinkButton onClick={openSupportMail}>
                {constants.SUPPORT}
            </LinkButton>
            <>
                <RecoveryKeyModal
                    show={modalView}
                    onHide={() => setModalView(false)}
                    somethingWentWrong={props.somethingWentWrong}
                />
                <LinkButton onClick={() => setModalView(true)}>
                    {constants.DOWNLOAD_RECOVERY_KEY}
                </LinkButton>
            </>
            <LinkButton onClick={() => router.push('changePassword')}>
                {constants.CHANGE_PASSWORD}
            </LinkButton>
            <LinkButton onClick={exportFiles}>{constants.EXPORT}</LinkButton>
            <div
                style={{
                    height: '1px',
                    marginTop: '40px',
                    background: '#242424',
                    width: '100%',
                }}
            ></div>
            <LinkButton
                variant="danger"
                onClick={() => props.setConfirmAction(CONFIRM_ACTION.LOGOUT)}
            >
                logout
            </LinkButton>
        </Menu>
    );
}
