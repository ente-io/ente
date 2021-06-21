import { DeadCenter } from 'pages/gallery';
import React, { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import { setupTwoFactor, TwoFactorSecret } from 'services/userService';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import EnteSpinner from './EnteSpinner';
import { CodeBlock, FreeFlowText } from './RecoveryKeyModal';


enum SetupMode {
    QR_CODE,
    MANUAL_CODE,
}

const QRCode = styled.img`
height:200px;
width:200px;
margin:1rem;
`;

export default function SetupTwoFactor() {
    const [setupMode, setSetupMode] = useState<SetupMode>(SetupMode.QR_CODE);
    const [twoFactorSecret, setTwoFactorSecret] = useState<TwoFactorSecret>(null);

    useEffect(() => {
        if (twoFactorSecret) {
            return;
        }
        const main = async () => {
            const twoFactorSecret = await setupTwoFactor();
            setTwoFactorSecret(twoFactorSecret);
        };
        main();
    }, []);

    return setupMode === SetupMode.QR_CODE ? (
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
        <Button block variant="link" style={{ marginBottom: '1rem' }} onClick={() => setSetupMode(SetupMode.QR_CODE)}>
            {constants.SCAN_QR_CODE}
        </Button>
    </>
    );
}
