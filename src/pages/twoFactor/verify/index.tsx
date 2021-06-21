import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import VerifyTwoFactor from 'components/VerifyTwoFactor';
import router from 'next/router';
import React from 'react';
import { Button, Card } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export default function Home() {
    return (
        <Container>
            <Card style={{ minWidth: '300px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px', minHeight: '400px' }}>
                    <Card.Title style={{ marginBottom: '32px' }}>
                        <LogoImg src='/icon.svg' />
                        {constants.TWO_FACTOR_AUTHENTICATION}
                    </Card.Title>
                    <VerifyTwoFactor callback={() => null} back={router.back} buttonText={constants.VERIFY} />
                    <div
                        style={{
                            display: 'flex',
                            flexDirection: 'column',
                            marginTop: '12px',
                        }}
                    >
                        <Button
                            variant="link"
                            onClick={() => router.push('/recover')}
                        >
                            {constants.LOST_DEVICE}
                        </Button>
                        <Button variant="link" onClick={router.back}>
                            {constants.GO_BACK}
                        </Button>
                    </div>
                </Card.Body>
            </Card>
        </Container>
    );
}
