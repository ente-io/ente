import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import { Button } from 'react-bootstrap';
import ConfirmLogout from 'components/ConfirmLogout';
import Spinner from 'react-bootstrap/Spinner';
import subscriptionService, {
    Subscription,
} from 'services/subscriptionService';
import ChangeDisabledMessage from './ChangeDisabledMessage';
import constants from 'utils/strings/constants';
import { logoutUser } from 'services/userService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { getToken } from 'utils/common/key';

interface Props {
    setNavbarIconView;
}
export default function Sidebar(props: Props) {
    const [logoutModalView, setLogoutModalView] = useState(false);
    const [
        changeDisabledMessageModalView,
        setChangeDisabledMessageModalView,
    ] = useState(false);
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
    return (
        <Menu
            isOpen={isOpen}
            onStateChange={(state) => setIsOpen(state.isOpen)}
            itemListElement="div"
        >
            <div style={{ outline: 'none' }}>
                <h4 style={{ marginBottom: '12px' }}>{constants.SUBSCRIPTION_PLAN}</h4>
                {
                    subscription?.productID == "free" ? constants.FREE_SUBSCRIPTION_INFO(subscription?.expiryTime) : constants.PAID_SUBSCRIPTION_INFO(subscription?.expiryTime)
                }
            </div>
            <div style={{ outline: 'none', marginTop: '40px' }}>
                <h4 style={{ marginBottom: '12px' }}>{constants.USAGE_DETAILS}</h4>
                <div>
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
            <>
                <ConfirmLogout
                    show={logoutModalView}
                    onHide={closeLogoutModal}
                    logout={logout}
                />
                <h4 style={{ cursor: 'pointer', color: '#F96C6C', marginTop: '40px' }} onClick={showLogoutModal}>
                    logout
                </h4>
            </>
        </Menu>
    );
}
