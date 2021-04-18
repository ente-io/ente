import Container from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import router from 'next/router';
import { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import billingService, { Subscription } from 'services/billingService';
import { SUBSCRIPTION_VERIFICATION_ERROR } from 'utils/common/errorUtil';
import constants from 'utils/strings/constants';

export default function SuccessRedirect() {
    const [response, setResponse] = useState<{
        subscription?: Subscription;
        error?: string;
    }>(null);
    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        const sessionId = urlParams.get('session_id');
        if (sessionId) {
            (async () => {
                try {
                    const subscription = await billingService.verifySubscription(
                        sessionId
                    );
                    setResponse({ subscription });
                } catch (e) {
                    setResponse({ error: SUBSCRIPTION_VERIFICATION_ERROR });
                }
            })();
        } else {
            setResponse({ error: SUBSCRIPTION_VERIFICATION_ERROR });
        }
    }, []);
    return (
        <Container style={{ textAlign: 'center', color: '#fff' }}>
            <div>
                {response ? (
                    <>
                        {response.subscription && (
                            <>
                                <h1>Your payment succeeded</h1>
                                <h4>
                                    {constants.RENEWAL_ACTIVE_SUBSCRIPTION_INFO(
                                        response.subscription?.expiryTime
                                    )}
                                </h4>
                            </>
                        )}
                        {response.error && (
                            <h4>
                                {constants.SUBSCRIPTION_VERIFICATION_FAILED}
                            </h4>
                        )}
                        <hr />
                        <Button
                            variant={
                                response.subscription ? 'success' : 'primary'
                            }
                            onClick={() => router.push('/gallery')}
                        >
                            Go Back To Gallery
                        </Button>
                    </>
                ) : (
                    <EnteSpinner />
                )}
            </div>
        </Container>
    );
}
