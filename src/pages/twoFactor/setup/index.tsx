import EnteSpinner from 'components/EnteSpinner';
import LogoImg from 'components/LogoImg';
import { CodeBlock, FreeFlowText } from 'components/RecoveryKeyModal';
import { DeadCenter } from 'pages/gallery';
import React, { useEffect, useState } from 'react';
import { Button, Card } from 'react-bootstrap';
import { enableTwoFactor, setupTwoFactor, TwoFactorSecret } from 'services/userService';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import Container from 'components/Container';
import { useRouter } from 'next/router';
import VerifyTwoFactor from 'components/VerifyTwoFactor';


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
    const router = useRouter();
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
    const onSubmit = async (otp: string) => {
        await enableTwoFactor(otp);
        router.push('/gallery');
    };
    return (
        <Container>
            <Card style={{ minWidth: '300px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px', minHeight: '400px' }}>
                    <DeadCenter>
                        <Card.Title style={{ marginBottom: '32px' }}>
                            <LogoImg src='/icon.svg' />
                            {constants.TWO_FACTOR_AUTHENTICATION}
                        </Card.Title>
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
                            <Button block variant="link" style={{ marginBottom: '1rem' }} onClick={() => setSetupMode(SetupMode.QR_CODE)}>
                                {constants.SCAN_QR_CODE}
                            </Button>
                        </>
                        )}
                        <div
                            style={{
                                height: '1px',
                                marginBottom: '20px',
                                width: '100%',
                            }}
                        />
                        <VerifyTwoFactor onSubmit={onSubmit} back={router.back} buttonText={constants.ENABLE} />
                        <Button variant="link" onClick={router.back}>
                            {constants.GO_BACK}
                        </Button>
                    </DeadCenter>
                </Card.Body>
            </Card>
        </Container>
    );
}
