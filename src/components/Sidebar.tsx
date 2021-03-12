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
            const usage = getToken() && (await subscriptionService.getUsage());

            SetUsage(usage);
        };
        main();
    }, [getToken()]);

    const logout = async () => {
        setLogoutModalView(false);
        setIsOpen(false);
        props.setNavbarIconView(false);
        logoutUser();
    };
    return (
        <Menu
            className="text-center"
            isOpen={isOpen}
            onStateChange={(state) => setIsOpen(state.isOpen)}
            itemListElement="div"
        >
            <div style={{ outline: 'none' }}>
                <h4>{constants.SUBCRIPTION_PLAN}</h4>
                {constants.SUBSCRIPTION_INFO(
                    subscription?.productID,
                    subscription?.expiryTime
                )}

                <Button
                    variant="success"
                    size="sm"
                    onClick={() =>
                        subscriptionService.redirectToCustomerPortal()
                    }
                >
                    {constants.CHANGE}
                </Button>
                <ChangeDisabledMessage
                    show={changeDisabledMessageModalView}
                    onHide={() => setChangeDisabledMessageModalView(false)}
                />
                <br />
                <br />
                <br />
            </div>
            <div style={{ outline: 'none' }}>
                <h4>{constants.USAGE_DETAILS}</h4>
                <div>
                    {usage ? (
                        constants.USAGE_INFO(
                            usage,
                            subscriptionService.convertBytesToGBs(
                                subscription?.storage
                            )
                        )
                    ) : (
                        <Spinner animation="border" />
                    )}
                </div>
                <br />
            </div>
            <>
                <ConfirmLogout
                    show={logoutModalView}
                    onHide={closeLogoutModal}
                    logout={logout}
                />
                <Button variant="danger" onClick={showLogoutModal}>
                    logout
                </Button>
            </>
        </Menu>
    );
}
