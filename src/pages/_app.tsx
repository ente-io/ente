import React, { useEffect, useState } from 'react';
import styled, {createGlobalStyle } from 'styled-components';
import Navbar from 'components/Navbar';
import constants from 'utils/strings/constants';
import 'bootstrap/dist/css/bootstrap.min.css';
import Button from 'react-bootstrap/Button';
import { clearKeys } from 'utils/storage/sessionStorage';
import { clearData, getData, LS_KEYS } from 'utils/storage/localStorage';
import { useRouter } from 'next/router';

const GlobalStyles = createGlobalStyle`
    html, body {
        padding: 0;
        margin: 0;
        font-family: Arial, Helvetica, sans-serif;
        height: 100%;
        flex: 1;
        display: flex;
        flex-direction: column;
        background-color: #303030;
    }

    #__next {
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .material-icons {
        vertical-align: middle;
        margin: 8px;
    }

    :root {
        --primary: #e26f99,
    };
`;

const Image = styled.img`
    max-height: 28px;
    margin-right: 5px;
`;

const FlexContainer = styled.div`
    flex: 1;
`;

export default function App({ Component, pageProps }) {
    const router = useRouter();
    const [user, setUser] = useState();

    useEffect(() => {
        const user = getData(LS_KEYS.USER);
        setUser(user);
        console.log(`%c${constants.CONSOLE_WARNING_STOP}`, 'color: red; font-size: 52px;');
        console.log(`%c${constants.CONSOLE_WARNING_DESC}`, 'font-size: 20px;');

        router.events.on('routeChangeComplete', () => {
            const user = getData(LS_KEYS.USER);
            setUser(user);
        });
    }, []);

    const logout = () => {
        clearKeys();
        clearData();
        router.push("/");
    }

    return (
        <>
            <GlobalStyles />
            <Navbar>
                <FlexContainer>
                    <Image src="/icon.png" />
                    {constants.COMPANY_NAME}
                </FlexContainer>
                {user && <Button variant='link' onClick={logout}>
                    <span className="material-icons">power_settings_new</span>
                </Button>}
            </Navbar>
            <Component />
        </>
    );
}