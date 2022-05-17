import VerticallyCenteredContainer from 'components/Container';
import LogoImg from 'components/LogoImg';
import VerifyTwoFactor from 'components/TwoFactor/VerifyForm';
import router from 'next/router';
import React, { useEffect, useState } from 'react';
import { Button, Card } from 'react-bootstrap';
import { logoutUser, verifyTwoFactor } from 'services/userService';
import { PAGES } from 'constants/pages';
import { User } from 'types/user';
import { setData, LS_KEYS, getData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import LinkButton from 'components/pages/gallery/LinkButton';

export default function Home() {
    const [sessionID, setSessionID] = useState('');

    useEffect(() => {
        const main = async () => {
            router.prefetch(PAGES.CREDENTIALS);
            const user: User = getData(LS_KEYS.USER);
            if (
                !user.isTwoFactorEnabled &&
                (user.encryptedToken || user.token)
            ) {
                router.push(PAGES.CREDENTIALS);
            } else if (!user?.email || !user.twoFactorSessionID) {
                router.push(PAGES.ROOT);
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
            router.push(PAGES.CREDENTIALS);
        } catch (e) {
            if (e.status === 404) {
                logoutUser();
            } else {
                throw e;
            }
        }
    };
    return (
        <VerticallyCenteredContainer>
            <Card style={{ minWidth: '300px' }} className="text-center">
                <Card.Body style={{ padding: '40px 30px', minHeight: '400px' }}>
                    <Card.Title style={{ marginBottom: '32px' }}>
                        <LogoImg src="/icon.svg" />
                        {constants.TWO_FACTOR}
                    </Card.Title>
                    <VerifyTwoFactor
                        onSubmit={onSubmit}
                        buttonText={constants.VERIFY}
                    />
                    <LinkButton onClick={router.back}>
                        {constants.GO_BACK}
                    </LinkButton>
                    <div
                        style={{
                            display: 'flex',
                            flexDirection: 'column',
                            marginTop: '12px',
                        }}>
                        <Button
                            variant="link"
                            onClick={() =>
                                router.push(PAGES.TWO_FACTOR_RECOVER)
                            }>
                            {constants.LOST_DEVICE}
                        </Button>
                        <Button variant="link" onClick={logoutUser}>
                            {constants.GO_BACK}
                        </Button>
                    </div>
                </Card.Body>
            </Card>
        </VerticallyCenteredContainer>
    );
}
