import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import React, { useEffect, useState } from 'react';
import { Alert, Card } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import router from 'next/router';
import { getToken } from 'utils/common/key';
import EnteSpinner from 'components/EnteSpinner';
import ChangeEmailForm from 'components/ChangeEmail';
import EnteCard from 'components/EnteCard';

function ChangeEmailPage() {
    const [email, setEmail] = useState('');
    const [waiting, setWaiting] = useState(true);
    const [showMessage, setShowMessage] = useState(false);
    const [showBigDialog, setShowBigDialog] = useState(false);

    useEffect(() => {
        const token = getToken();
        if (!token) {
            router.push('/');
            return;
        }
        setWaiting(false);
    }, []);

    return (
        <Container>
            {waiting ? (
                <EnteSpinner>
                    <span className="sr-only">Loading...</span>
                </EnteSpinner>
            ) : (
                <EnteCard size={showBigDialog ? 'md' : 'sm'}>
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <Card.Title style={{ marginBottom: '32px' }}>
                            <LogoImg src="/icon.svg" />
                            {constants.UPDATE_EMAIL}
                        </Card.Title>
                        <Alert
                            variant="success"
                            show={showMessage}
                            style={{ paddingBottom: 0 }}
                            transition
                            dismissible
                            onClose={() => setShowMessage(false)}>
                            {constants.EMAIL_SENT({ email })}
                        </Alert>
                        <ChangeEmailForm
                            showMessage={(value) => {
                                setShowMessage(value);
                                setShowBigDialog(value);
                            }}
                            setEmail={setEmail}
                        />
                    </Card.Body>
                </EnteCard>
            )}
        </Container>
    );
}

export default ChangeEmailPage;
