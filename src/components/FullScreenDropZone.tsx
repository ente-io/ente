import React, { useEffect, useState } from 'react';
import styled from 'styled-components';
import { slide as Menu } from 'react-burger-menu';
import { Button } from 'react-bootstrap';
import ConfirmLogout from 'components/ConfirmLogout';
import Spinner from 'react-bootstrap/Spinner';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import subscriptionService from 'services/subscriptionService';

export const getColor = (props) => {
    if (props.isDragActive) {
        return '#00e676';
    } else {
        return '#191919';
    }
};

export const enableBorder = (props) => (props.isDragActive ? 'solid' : 'none');
const DropDiv = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
`;

const Overlay = styled.div<{ isDragActive: boolean }>`
    border-width: 8px;

    outline: none;
    transition: border 0.24s ease-in-out;
    height: 100%;
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    font-size: 24px;
    font-weight: 900;
    text-align: center;
    position: absolute;
    border-color: ${(props) => getColor(props)};
    border-style: solid;
    background: rgba(0, 0, 0, 0.9);
    z-index: 9;
`;

type Props = React.PropsWithChildren<{
    getRootProps: any;
    getInputProps: any;
    isDragActive;
    onDragLeave;
    onDragEnter;
    logout;
}>;

interface Subscription {
    id: number;
    userID: number;
    productID: string;
    storage: number;
    originalTransactionID: string;
    expiryTime: number;
    paymentProvider: string;
}
export default function FullScreenDropZone(props: Props) {
    const [logoutModalView, setLogoutModalView] = useState(false);

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
    return (
        <DropDiv {...props.getRootProps()} onDragEnter={props.onDragEnter}>
            <Menu className="text-center">
                <div>
                    Subscription Plans{' '}
                    <Button variant="success" size="sm">
                        Change
                    </Button>
                    <br />
                    <br />
                    you are currently on{' '}
                    <strong>{subscription?.productID}</strong> plan
                    <br />
                    <br />
                    <br />
                </div>
                <div>
                    <h4>Usage Details</h4>
                    <br />
                    <div>
                        {usage ? (
                            `you have used ${usage} GB out of your ${subscriptionService.convertBytesToGBs(
                                subscription.storage
                            )} GB quota`
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
            <input {...props.getInputProps()} />
            {props.isDragActive && (
                <Overlay
                    onDragLeave={props.onDragLeave}
                    isDragActive={props.isDragActive}
                >
                    drop to backup your files
                </Overlay>
            )}
            {props.children}
        </DropDiv>
    );
}
