/* eslint-disable @typescript-eslint/no-unused-vars */
import React, { useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { DeadCenter } from 'pages/gallery';
import { Button } from 'react-bootstrap';
import { setupTwoFactor, TwoFactorSecret } from 'services/userService';
import styled from 'styled-components';
import EnteSpinner from './EnteSpinner';
import { CodeBlock, FreeFlowText } from './RecoveryKeyModal';
import OtpInput from 'react-otp-input';

const QRCode = styled.img`
height:200px;
width:200px;
margin:20px;
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
    const [twoFactorSecret, setTwoFactorSecret] = useState<TwoFactorSecret>(null);
    useEffect(() => {
        if (!props.show || twoFactorSecret) {
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
                title: constants.TWO_FACTOR_AUTHENTICATION,
                close: {
                    text: constants.CANCEL,
                    variant: 'danger',
                },
                staticBackdrop: true,
                proceed: {
                    text: constants.CONTINUE,
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
                <CodeBlock height={100}>
                    {!twoFactorSecret ? <EnteSpinner /> : (
                        <FreeFlowText>
                            {twoFactorSecret.secretCode}
                        </FreeFlowText>

                    )}
                </CodeBlock>
                <Button block variant="link" onClick={() => setSetupMode(SetupMode.QR_CODE)}>
                    {constants.SCAN_QR_CODE}
                </Button>
            </>
            )}
            {setupMode && <OtpInput
                value={this.state.otp}
                onChange={this.handleChange}
                numInputs={6}
                separator={<span>-</span>}
            />}
        </MessageDialog >
    );
}
export default TwoFactorModal;
