import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import ConfirmDialog from 'components/ConfirmDialog';
import Spinner from 'react-bootstrap/Spinner';
import billingService, { Subscription } from 'services/billingService';
import constants from 'utils/strings/constants';
import { logoutUser } from 'services/userService';
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

enum Action {
    logout = 'logout',
    cancelSubscription = 'cancel_subscription',
}
interface Props {
    setNavbarIconView;
    setPlanModalView;
    setBannerMessage;
}
export default function Sidebar(props: Props) {
    const [confirmModalView, setConfirmModalView] = useState(false);
    function closeConfirmModal() {
        setConfirmModalView(false);
    }
    const [usage, SetUsage] = useState<string>(null);
    const [action, setAction] = useState<string>(null);
    const [user, setUser] = useState(null);
    const [subscription, setSubscription] = useState<Subscription>(null);
    useEffect(() => {
        setUser(getData(LS_KEYS.USER));
        setSubscription(getUserSubscription());
    }, []);
    const [isOpen, setIsOpen] = useState(false);
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

    const logout = async () => {
        setConfirmModalView(false);
        setIsOpen(false);
        props.setNavbarIconView(false);
        logoutUser();
    };

    const cancelSubscription = async () => {
        try {
            await billingService.cancelSubscription();
        } catch (e) {
            props.setBannerMessage({
                message: constants.SUBSCRIPTION_CANCEL_FAILED,
                variant: 'danger',
            });
        }
        props.setBannerMessage({
            message: constants.SUBSCRIPTION_CANCEL_SUCCESS,
            variant: 'secondary',
        });
        setConfirmModalView(false);
        setIsOpen(false);
    };

    let callback = new Map<string, Function>();
    callback[Action.logout] = logout;
    callback[Action.cancelSubscription] = cancelSubscription;
    function openFeedbackURL() {
        const feedbackURL: string =
            getEndpoint() + '/users/feedback?token=' + getToken();
        var win = window.open(feedbackURL, '_blank');
        win.focus();
    }

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
                                    setAction(Action.cancelSubscription);
                                    setConfirmModalView(true);
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
                >
                    support
                </a>
            </h5>
            <>
                <ConfirmDialog
                    show={confirmModalView}
                    onHide={closeConfirmModal}
                    callback={callback}
                    action={action}
                />
                <h5
                    style={{
                        cursor: 'pointer',
                        color: '#F96C6C',
                        marginTop: '30px',
                    }}
                    onClick={() => {
                        setAction(Action.logout);
                        setConfirmModalView(true);
                    }}
                >
                    logout
                </h5>
            </>
        </Menu>
    );
}
