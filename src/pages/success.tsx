import Container from 'components/Container';
import router from 'next/router';
import { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import subscriptionService from 'services/subscriptionService';

export default function SuccessRedirect() {
    const [sessionData, setSessionData] = useState(null);
    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        const sessionId = urlParams.get('session_id');
        if (sessionId) {
            (async () => {
                const sessionJSON = await subscriptionService.getCheckoutSession(
                    sessionId
                );
                setSessionData(sessionJSON);
            })();
        }
    }, []);
    return (
        <Container style={{ color: '#fff' }}>
            <div>
                <h1>Your payment succeeded</h1>
                <Button onClick={() => router.push('/gallery')}>Go Home</Button>
                <h4>View CheckoutSession response:</h4>
            </div>
            <div>
                <pre style={{ color: '#fff' }}>{sessionData}</pre>
            </div>
        </Container>
    );
}
