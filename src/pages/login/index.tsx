import React, { useState, useEffect, useContext } from 'react';
import { useRouter } from 'next/router';
import EnteSpinner from 'components/EnteSpinner';
import { AppContext } from 'pages/_app';
import Login from 'components/Login';
import Container from 'components/Container';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import Card from 'react-bootstrap/Card';
import { PAGES } from 'types';

export default function Home() {
    const router = useRouter();
    const appContext = useContext(AppContext);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        router.prefetch(PAGES.VERIFY);
        router.prefetch(PAGES.SIGNUP);
        const user = getData(LS_KEYS.USER);
        if (user?.email) {
            router.push(PAGES.VERIFY);
        }
        setLoading(false);
        appContext.showNavBar(false);
    }, []);

    const register = () => {
        router.push(PAGES.SIGNUP);
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
