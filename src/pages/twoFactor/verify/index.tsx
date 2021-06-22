import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import VerifyTwoFactor from 'components/VerifyTwoFactor';
import router from 'next/router';
import React, { useEffect, useState } from 'react';
import { Button, Card } from 'react-bootstrap';
import { logoutUser, verifyTwoFactor } from 'services/userService';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';

export default function Home() {
    const [email, setEmail] = useState('');
    const [ott, setOTT] = useState('');

    useEffect(() => {
        const main = async () => {
            router.prefetch('/credentials');
            const user = getData(LS_KEYS.USER);
            if (!user?.email) {
                router.push('/');
            } else {
                setEmail(user.email);
                setOTT(user.twoFactorOTT);
            }
        };
        main();
    }, []);

    const onSubmit = async (otp: string) => {
        const resp = await verifyTwoFactor(email, otp, ott);
        const { keyAttributes, encryptedToken, token, id } = resp;
        setData(LS_KEYS.USER, {
            email,
            token,
            encryptedToken,
            id,
        });
        keyAttributes && setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
        router.push('/credentials');
    };
    return (
        <Container>
            <Card style={{ minWidth: '300px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px', minHeight: '400px' }}>
                    <Card.Title style={{ marginBottom: '32px' }}>
                        <LogoImg src='/icon.svg' />
                        {constants.TWO_FACTOR_AUTHENTICATION}
                    </Card.Title>
                    <VerifyTwoFactor onSubmit={onSubmit} back={router.back} buttonText={constants.VERIFY} />
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
                        <Button variant="link" onClick={logoutUser}>
                            {constants.GO_BACK}
                        </Button>
                    </div>
                </Card.Body>
            </Card>
        </Container>
    );
}
