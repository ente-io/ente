import Container from 'components/Container';
import router from 'next/router';
import { useEffect, useState } from 'react';
import { Button, Spinner } from 'react-bootstrap';
import subscriptionService, {
    Subscription,
} from 'services/subscriptionService';
import constants from 'utils/strings/constants';

export default function SuccessRedirect() {
    const [subscription, setSubscription] = useState<Subscription>(null);
    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        const sessionId = urlParams.get('session_id');
        if (sessionId) {
            (async () => {
                const subscription = await subscriptionService.verifySubscription(
                    sessionId
                );
                setSubscription(subscription);
            })();
        }
    }, []);
    return (
        <Container style={{ color: '#fff' }}>
            <div>
                {subscription ? (
                    <>
                        <h1>Your payment succeeded</h1>
                        <h4>
                            {constants.SUBSCRIPTION_INFO(
                                subscription?.productID,
                                subscription?.expiryTime
                            )}
                        </h4>
                        <Button onClick={() => router.push('/gallery')}>
                            Go Back To Gallery
                        </Button>
                    </>
                ) : (
                    <Spinner animation="border" />
                )}
            </div>
        </Container>
    );
}
