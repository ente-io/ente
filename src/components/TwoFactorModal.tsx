/* eslint-disable @typescript-eslint/no-unused-vars */
import React, { useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { DeadCenter } from 'pages/gallery';
import { Button } from 'react-bootstrap';
import { setupTwoFactor, TwoFactorSector } from 'services/userService';
import styled from 'styled-components';
import EnteSpinner from './EnteSpinner';

const QRCode = styled.img`
height:200px;
width:200px;
`;

interface Props {
    show: boolean;
    onHide: () => void;
    somethingWentWrong: any;
}

enum SetupMode {
    QR_CODE,
    MANUAL_CODE,
}
function TwoFactorModal({ somethingWentWrong, ...props }: Props) {
    const [setupMode, setSetupMode] = useState<SetupMode>(SetupMode.QR_CODE);
    const [twoFactorSecret, setTwoFactorSecret] = useState<TwoFactorSector>(null);
    useEffect(() => {
        if (!props.show) {
            return;
        }
        const main = async () => {
            const twoFactorSecret = await setupTwoFactor();
            setTwoFactorSecret(twoFactorSecret);
        };
        main();
    }, [props.show]);

    return (
        <MessageDialog
            {...props}
            attributes={{
                title: constants.DOWNLOAD_RECOVERY_KEY,
                close: {
                    text: constants.SAVE_LATER,
                    variant: 'danger',
                },
                staticBackdrop: true,
                proceed: {
                    text: constants.SAVE,
                    action: () => null,
                    disabled: false,
                    variant: 'success',
                },
            }}
        >
            {setupMode === SetupMode.QR_CODE ? (
                <>
                    <p>{constants.TWO_FACTOR_AUTHENTICATION_QR_INSTRUCTION}</p>
                    <DeadCenter>
                        {!twoFactorSecret ? <EnteSpinner /> :
                            <QRCode src={`data:image/png;base64,${twoFactorSecret.qrCode}`} />
                        }
                        <Button block variant="link" onClick={() => setSetupMode(SetupMode.MANUAL_CODE)}>
                            {constants.ENTER_CODE_MANUALLY}
                        </Button>
                    </DeadCenter>
                </>
            ) : (<>
                <p>{constants.TWO_FACTOR_AUTHENTICATION_MANUAL_CODE_INSTRUCTION}</p>
                <DeadCenter>
                    <div style={{ width: '300px', height: '30px', backgroundColor: 'red', marginBottom: '10px' }}>
                    </div>
                    <Button block variant="link" onClick={() => setSetupMode(SetupMode.QR_CODE)}>
                        {constants.ENTER_CODE_MANUALLY}
                    </Button>
                </DeadCenter>
            </>
            )
            }
        </MessageDialog>
    );
}
export default TwoFactorModal;
