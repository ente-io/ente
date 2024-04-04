import type { AppProps } from "next/app";
import Head from "next/head";
import React from "react";
import S from "utils/strings";
import "../styles/globals.css";

const MyApp = ({ Component, pageProps }: AppProps): React.JSX.Element => {
    return (
        <>
            <Head>
                <title>{S.title}</title>
            </Head>
            <Component {...pageProps} />
        </>
    );
};

export default MyApp;
