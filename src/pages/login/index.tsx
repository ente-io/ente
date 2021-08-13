import React, { useState, useEffect, useContext } from 'react';
import { useRouter } from 'next/router';
import EnteSpinner from 'components/EnteSpinner';
import { AppContext } from 'pages/_app';
import Login from 'components/Login';
import Container from 'components/Container';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import Card from 'react-bootstrap/Card';

export default function Home() {
    const router = useRouter();
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        router.prefetch('/verify');
        router.prefetch('/signup');
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push('/verify');
        }
        setLoading(false);
        appContext.showNavBar(false);
    }, []);

    const register = () => {
        router.push('/signup');
    };

    return (
        <Container>
            {loading ? (
                <EnteSpinner>
                    <span className="sr-only">Loading...</span>
                </EnteSpinner>
            ) : (
                <Card style={{ minWidth: '320px' }} className="text-center">
                    <Card.Body style={{ padding: '40px 30px' }}>
                        <Login signUp={register} />
                    </Card.Body>
                </Card>
            )}
        </Container>
    );
}
