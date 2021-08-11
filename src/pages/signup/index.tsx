import React, { useState, useEffect, useContext } from 'react';
import { useRouter } from 'next/router';
import Card from 'react-bootstrap/Card';
import { AppContext } from 'pages/_app';
import Container from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import SignUp from 'components/SignUp';

export default function SignUpPage() {
    const router = useRouter();
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        router.prefetch('/verify');
        router.prefetch('/login');
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push('/verify');
        }
        setLoading(false);
        appContext.showNavBar(false);
    }, []);

    const login = () => {
        router.push('/login');
    };

    return (
        <Container>
            {loading ? (
                <EnteSpinner />
            ) : (
                <Card style={{ minWidth: '320px' }} className="text-center">
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <SignUp login={login} />
                    </Card.Body>
                </Card>
            )}
        </Container>
    );
}
