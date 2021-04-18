import Container from 'components/Container';
import router from 'next/router';
import { useEffect } from 'react';
import constants from 'utils/strings/constants';

export default function CancelRedirect() {
    useEffect(() => {
        setTimeout(() => router.push('/gallery'), 1000);
    }, []);
    return (
        <Container style={{ color: '#fff' }}>
            {constants.SUBSCRIPTION_PURCHASE_CANCELLED()}
        </Container>
    );
}
