import Container from 'components/Container';
import LogoImg from 'components/LogoImg';
import React, { useEffect, useState } from 'react';
import { Alert } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import router from 'next/router';
import ChangeEmailForm from 'components/ChangeEmail';
import { PAGES } from 'constants/pages';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { Box, Card, CardContent } from '@mui/material';
import LinkButton from 'components/pages/gallery/LinkButton';

function ChangeEmailPage() {
    const [email, setEmail] = useState(null);
    const [showMessage, setShowMessage] = useState(false);
    const [showBigDialog, setShowBigDialog] = useState(false);

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        if (!user?.token) {
            router.push(PAGES.ROOT);
        }
    }, []);

    const goToGallery = () => router.push(PAGES.GALLERY);

    return (
        <Container>
            <Card sx={{ minWidth: showBigDialog ? '460px' : '320px' }}>
                <CardContent>
                    <Container disableGutters sx={{ py: 2 }}>
                        <Box mb={2}>
                            <LogoImg src="/icon.svg" />
                            {constants.CHANGE_EMAIL}
                        </Box>
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
                        <LinkButton onClick={goToGallery}>
                            {constants.GO_BACK}
                        </LinkButton>
                    </Container>
                </CardContent>
            </Card>
        </Container>
    );
}

export default ChangeEmailPage;
