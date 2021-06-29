import { useRouter } from 'next/router';
import { DeadCenter, SetLoading } from 'pages/gallery';
import React, { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import { disableTwoFactor, getTwoFactorStatus } from 'services/userService';
import styled from 'styled-components';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import MessageDialog, { SetDialogMessage } from './MessageDialog';

interface Props {
    show: boolean;
    onHide: () => void;
    setDialogMessage: SetDialogMessage;
    setLoading: SetLoading
    closeSidebar: () => void
}

const Row = styled.div`
    display:flex;
    align-items:center;
    margin-bottom:20px;
    flex:1
`;

const Label = styled.div`
    width:70%;
`;
function TwoFactorModal(props: Props) {
    const router = useRouter();
    const [isTwoFactorEnabled, setTwoFactorStatus] = useState(false);

    useEffect(() => {
        if (!props.show) {
            return;
        }
        const isTwoFactorEnabled = getData(LS_KEYS.USER).isTwoFactorEnabled ?? false;
        setTwoFactorStatus(isTwoFactorEnabled);
        const main = async () => {
            const isTwoFactorEnabled = await getTwoFactorStatus();
            setTwoFactorStatus(isTwoFactorEnabled);
        };
        main();
    }, [props.show]);
    const warnTwoFactorDisable = async () => {
        props.setDialogMessage({
            title: constants.DISABLE_TWO_FACTOR,
            staticBackdrop: true,
            content: constants.DISABLE_TWO_FACTOR_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                variant: 'danger',
                text: constants.DISABLE,
                action: twoFactorDisable,
            },
        });
    };
    const twoFactorDisable = async () => {
        await disableTwoFactor();
        setData(LS_KEYS.USER, { ...getData(LS_KEYS.USER), isTwoFactorEnabled: false });
        props.onHide();
        props.closeSidebar();
    };
    const warnTwoFactorReconfigure = async () => {
        props.setDialogMessage({
            title: constants.UPDATE_TWO_FACTOR,
            staticBackdrop: true,
            content: constants.UPDATE_TWO_FACTOR_MESSAGE,
            close: { text: constants.CANCEL },
            proceed: {
                variant: 'success',
                text: constants.UPDATE,
                action: reconfigureTwoFactor,
            },
        });
    };
    const reconfigureTwoFactor = async () => {
        router.push('/two-factor/setup');
    };
    return (
        <MessageDialog
            show={props.show}
            onHide={props.onHide}
            {...(!isTwoFactorEnabled && { size: 'lg' })}
            attributes={{
                title: constants.TWO_FACTOR_AUTHENTICATION,
                staticBackdrop: true,
            }}

        >
            <div {...(!isTwoFactorEnabled ? { style: { padding: '10px 40px 30px 40px' } } : { style: { padding: '10px' } })}>
                {
                    isTwoFactorEnabled ?
                        <>
                            <Row>
                                <Label>{constants.DISABLE_TWO_FACTOR_HINT} </Label><Button variant={'outline-danger'} style={{ width: '30%' }} onClick={warnTwoFactorDisable}>{constants.DISABLE}</Button>
                            </Row>
                            <Row>
                                <Label>{constants.UPDATE_TWO_FACTOR_HINT}</Label> <Button variant={'outline-success'} style={{ width: '30%' }} onClick={warnTwoFactorReconfigure}>{constants.RECONFIGURE}</Button>
                            </Row>
                        </> : (
                            <DeadCenter>
                                <p>{constants.TWO_FACTOR_INFO}</p>
                                <div style={{ height: '10px' }} />
                                <Button variant="outline-success" onClick={() => router.push('/two-factor/setup')}>{constants.ENABLE_TWO_FACTOR}</Button>
                            </DeadCenter>
                        )
                }
            </div>
        </MessageDialog >
    );
}
export default TwoFactorModal;
