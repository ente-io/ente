import Container from 'components/Container';
import { useEffect, useState } from 'react';
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
        <Container style={{ color: '#aaa' }}>
            <div>
                <h1>Your payment succeeded</h1>
                <h4>View CheckoutSession response:</h4>
            </div>
            <div>
                <pre>{sessionData}</pre>
            </div>
        </Container>
    );
}
