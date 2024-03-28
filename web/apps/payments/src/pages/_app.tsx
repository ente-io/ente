import '../styles/globals.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import type { AppProps } from 'next/app';
import React from 'react';
import constants from 'utils/strings/constants';
import Head from 'next/head';

function MyApp({ Component, pageProps }: AppProps) {
    return (
        <>
            <Head>
                <title>{constants.TITLE}</title>
            </Head>
            <Component {...pageProps} />
        </>
    );
}
export default MyApp;
