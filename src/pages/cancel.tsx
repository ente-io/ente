import Container from 'components/Container';
import router from 'next/router';
import { Button } from 'react-bootstrap';

export default function CancelRedirect() {
    return (
        <Container style={{ color: '#fff' }}>
            <div>
                <h1>Your payment was Canceled</h1>
                <br />
                <Button onClick={() => router.push('/gallery')}>
                    Go Back To Gallery
                </Button>
            </div>
        </Container>
    );
}
