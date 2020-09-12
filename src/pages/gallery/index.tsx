import React, { useContext, useEffect } from 'react';
import Link from 'next/link';
import { AppContext } from 'pages/_app';
import { useRouter } from 'next/router';
import Container from 'components/Container';
import Card from 'react-bootstrap/Card';
import Button from 'react-bootstrap/Button';
import { clearData } from 'utils/sessionStorage';

export default function Gallery() {
    const context = useContext(AppContext);
    const router = useRouter();

    useEffect(() => {
        if (!context.key) {
            router.push("/");
        }
    }, []);

    const logout = () => {
        context.setKey(null);
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
