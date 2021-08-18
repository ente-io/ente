import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import VerifyTwoFactor from 'components/VerifyTwoFactor';
import router from 'next/router';
import React, { useEffect, useState } from 'react';
import { Button, Card } from 'react-bootstrap';
import { logoutUser, User, verifyTwoFactor } from 'services/userService';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';

export default function Home() {
    const [sessionID, setSessionID] = useState('');

    useEffect(() => {
        const main = async () => {
            router.prefetch('/credentials');
            const user: User = getData(LS_KEYS.USER);
            if (
                !user.isTwoFactorEnabled &&
                (user.encryptedToken || user.token)
            ) {
                router.push('/credential');
            } else if (!user?.email || !user.twoFactorSessionID) {
                router.push('/');
            } else {
                setSessionID(user.twoFactorSessionID);
            }
        };
        main();
    }, []);

    const onSubmit = async (otp: string) => {
        try {
            const resp = await verifyTwoFactor(otp, sessionID);
            const { keyAttributes, encryptedToken, token, id } = resp;
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                token,
                encryptedToken,
                id,
            });
            setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);
            router.push('/credentials');
        } catch (e) {
            if (e.status === 404) {
                logoutUser();
            } else {
                throw e;
            }
        }
    };
    return (
        <Container>
            <Card style={{ minWidth: '300px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px', minHeight: '400px' }}>
                    <Card.Title style={{ marginBottom: '32px' }}>
                        <LogoImg src="/icon.svg" />
                        {constants.TWO_FACTOR}
                    </Card.Title>
                    <VerifyTwoFactor
                        onSubmit={onSubmit}
                        back={router.back}
                        buttonText={constants.VERIFY}
                    />
                    <div
                        style={{
                            display: 'flex',
                            flexDirection: 'column',
                            marginTop: '12px',
                        }}>
                        <Button
                            variant="link"
                            onClick={() => router.push('/two-factor/recover')}>
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
