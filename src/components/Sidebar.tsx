import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import ConfirmLogout from 'components/ConfirmLogout';
import Spinner from 'react-bootstrap/Spinner';
import subscriptionService, {
    Subscription,
} from 'services/subscriptionService';
import constants from 'utils/strings/constants';
import { logoutUser } from 'services/userService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { getToken } from 'utils/common/key';
import { getEndpoint } from 'utils/common/apiUtil';
import { Button } from 'react-bootstrap';

interface Props {
    setNavbarIconView;
}
export default function Sidebar(props: Props) {
    const [logoutModalView, setLogoutModalView] = useState(false);
    function showLogoutModal() {
        setLogoutModalView(true);
    }
    function closeLogoutModal() {
        setLogoutModalView(false);
    }
    const [usage, SetUsage] = useState<string>(null);
    const subscription: Subscription = getData(LS_KEYS.SUBSCRIPTION);
    const [isOpen, setIsOpen] = useState(false);
    useEffect(() => {
        const main = async () => {
            if (!isOpen) {
                return;
            }
            const usage = await subscriptionService.getUsage();

            SetUsage(usage);
        };
        main();
    }, [isOpen]);

    const logout = async () => {
        setLogoutModalView(false);
        setIsOpen(false);
        props.setNavbarIconView(false);
        logoutUser();
    };

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
            <div style={{ outline: 'none' }}>
                <h5 style={{ marginBottom: '12px' }}>
                    {constants.SUBSCRIPTION_PLAN}
                </h5>
                <div style={{ color: '#959595' }}>
                    {subscription?.productID == 'free'
                        ? constants.FREE_SUBSCRIPTION_INFO(
                              subscription?.expiryTime
                          )
                        : constants.PAID_SUBSCRIPTION_INFO(
                              subscription?.expiryTime
                          )}
                </div>
                <Button
                    variant="success"
                    size="sm"
                    onClick={() =>
                        subscriptionService.redirectToCustomerPortal()
                    }
                >
                    {constants.CHANGE}
                </Button>
            </div>
            <div style={{ outline: 'none', marginTop: '30px' }}>
                <h5 style={{ marginBottom: '12px' }}>
                    {constants.USAGE_DETAILS}
                </h5>
                <div style={{ color: '#959595' }}>
                    {usage ? (
                        constants.USAGE_INFO(
                            usage,
                            Math.ceil(
                                Number(
                                    subscriptionService.convertBytesToGBs(
                                        subscription?.storage
                                    )
                                )
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
                <ConfirmLogout
                    show={logoutModalView}
                    onHide={closeLogoutModal}
                    logout={logout}
                />
                <h5
                    style={{
                        cursor: 'pointer',
                        color: '#F96C6C',
                        marginTop: '30px',
                    }}
                    onClick={showLogoutModal}
                >
                    logout
                </h5>
            </>
        </Menu>
    );
}
