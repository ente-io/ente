import React, { useState, createContext } from 'react';
import styled, {createGlobalStyle } from 'styled-components';
import Navbar from 'components/Navbar';
import constants from 'utils/strings/constants';
import 'bootstrap/dist/css/bootstrap.min.css';

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

export interface IAppContext {
    key: string;
    setKey: (key: string) => void
}

export const AppContext = createContext<IAppContext>(null);

export default function App({ Component, pageProps }) {
    const [key, setKey] = useState<string>();
    return (
        <AppContext.Provider value={{ key, setKey }}>
            <GlobalStyles />
            <Navbar>
                <Image src="/icon.png" />
                {constants.COMPANY_NAME}
            </Navbar>
            <Component />
        </AppContext.Provider>
    );
}