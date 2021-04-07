import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import { CONFIRM_ACTION } from 'components/ConfirmDialog';
import Spinner from 'react-bootstrap/Spinner';
import billingService, { Subscription } from 'services/billingService';
import constants from 'utils/strings/constants';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { getToken } from 'utils/common/key';
import { getEndpoint } from 'utils/common/apiUtil';
import { Button } from 'react-bootstrap';
import {
    isPlanActive,
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

interface Props {
    files: file[];
    collections: collection[];
    setConfirmAction: any;
    somethingWentWrong: any;
    setPlanModalView;
    setBannerMessage;
}
export default function Sidebar(props: Props) {
    const [usage, SetUsage] = useState<string>(null);
    const [action, setAction] = useState<string>(null);
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
                    {isPlanActive(subscription) ? (
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
                <div style={{ display: 'flex' }}>
                    {isSubscribed(subscription) ? (
                        <>
                            <Button
                                variant="success"
                                size="sm"
                                onClick={() => {
                                    setIsOpen(false);
                                    props.setPlanModalView(true);
                                }}
                            >
                                {constants.MANAGE}
                            </Button>
                            <Button
                                variant="danger"
                                size="sm"
                                onClick={() => {
                                    props.setConfirmAction(
                                        CONFIRM_ACTION.CANCEL_SUBSCRIPTION
                                    );
                                }}
                                style={{ marginLeft: '10px' }}
                            >
                                {constants.CANCEL_SUBSCRIPTION}
                            </Button>
                        </>
                    ) : (
                        <Button
                            variant="success"
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
                        <Spinner animation="border" />
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
            <h5
                style={{ cursor: 'pointer', marginTop: '40px' }}
                onClick={openFeedbackURL}
            >
                request feature
            </h5>
            <h5 style={{ cursor: 'pointer', marginTop: '30px' }}>
                <a
                    href="mailto:contact@ente.io"
                    style={{ textDecoration: 'inherit', color: 'inherit' }}
                    target="_blank"
                    rel="noreferrer noopener"
                >
                    support
                </a>
            </h5>

            <RecoveryKeyModal
                show={modalView}
                onHide={() => setModalView(false)}
                somethingWentWrong={props.somethingWentWrong}
            />
            <h5
                style={{ cursor: 'pointer', marginTop: '30px' }}
                onClick={() => setModalView(true)}
            >
                {constants.DOWNLOAD_RECOVERY_KEY}
            </h5>
            <h5
                style={{ cursor: 'pointer', marginTop: '30px' }}
                onClick={() => router.push('changePassword')}
            >
                {constants.CHANGE_PASSWORD}
            </h5>
            <h5
                style={{ cursor: 'pointer', marginTop: '30px' }}
                onClick={exportFiles}
            >
                {constants.EXPORT}
            </h5>
            <div
                style={{
                    height: '1px',
                    marginTop: '40px',
                    background: '#242424',
                    width: '100%',
                }}
            ></div>
            <h5
                style={{
                    cursor: 'pointer',
                    color: '#F96C6C',
                    marginTop: '30px',
                }}
                onClick={() => props.setConfirmAction(CONFIRM_ACTION.LOGOUT)}
            >
                logout
            </h5>
        </Menu>
    );
}
