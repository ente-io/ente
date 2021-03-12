import React, { useEffect, useState } from 'react';

import { slide as Menu } from 'react-burger-menu';
import { Button } from 'react-bootstrap';
import ConfirmLogout from 'components/ConfirmLogout';
import Spinner from 'react-bootstrap/Spinner';
import { clearData, getData, LS_KEYS } from 'utils/storage/localStorage';
import subscriptionService, {
    Subscription,
} from 'services/subscriptionService';
import ChangeDisabledMessage from './ChangeDisabledMessage';
import constants from 'utils/strings/constants';
import { clearKeys } from 'utils/storage/sessionStorage';
import router from 'next/router';
import localForage from 'localforage';

export default function Sidebar(props) {
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

    useEffect(() => {
        const main = async () => {
            const usage = await subscriptionService.getUsage();

            SetUsage(usage);
        };
        main();
    });

    const logout = async () => {
        clearKeys();
        clearData();
        props.setUploadButtonView(false);
        localForage.clear();
        const cache = await caches.delete('thumbs');
        router.push('/');
    };

    return (
        <Menu className="text-center">
            <div>
                {constants.SUBCRIPTION_PLAN}
                <Button
                    variant="success"
                    size="sm"
                    onClick={() => setChangeDisabledMessageModalView(true)}
                >
                    {constants.CHANGE}
                </Button>
                <ChangeDisabledMessage
                    show={changeDisabledMessageModalView}
                    onHide={() => setChangeDisabledMessageModalView(false)}
                />
                <br />
                <br />
                {constants.SUBSCRIPTION_INFO(subscription?.productID)}
                <br />
                <br />
            </div>
            <div>
                <h4>{constants.USAGE_DETAILS}</h4>
                <br />
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
                <br />
            </div>
            <>
                <ConfirmLogout
                    show={logoutModalView}
                    onHide={closeLogoutModal}
                    logout={() => {
                        setLogoutModalView(false);
                        props.logout();
                    }}
                />
                <Button variant="danger" onClick={showLogoutModal}>
                    logout
                </Button>
            </>
        </Menu>
    );
}
