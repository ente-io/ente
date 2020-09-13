import React, { useContext, useEffect } from 'react';
import { useRouter } from 'next/router';
import Container from 'components/Container';
import Card from 'react-bootstrap/Card';
import Button from 'react-bootstrap/Button';
import { clearData } from 'utils/storage/localStorage';
import { clearKeys, getKey, SESSION_KEYS } from 'utils/storage/sessionStorage';

export default function Gallery() {
    const router = useRouter();

    useEffect(() => {
        const key = getKey(SESSION_KEYS.ENCRYPTION_KEY);
        if (!key) {
            router.push("/");
        }
    }, []);

    const logout = () => {
        clearKeys();
        clearData();
        router.push('/');
    }

    return (<Container>
        <Card className="text-center">
            <Card.Body>
                Imagine a very nice and secure gallery of your memories here.<br/>
                <br/>
                <Button block onClick={logout}>Logout</Button>
            </Card.Body>
        </Card>
    </Container>);
}
