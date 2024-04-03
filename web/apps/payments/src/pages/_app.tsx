import type { AppProps } from "next/app";
import Head from "next/head";
import React from "react";
import S from "utils/strings";
import "../styles/globals.css";

function MyApp({ Component, pageProps }: AppProps) {
    return (
        <>
            <Head>
                <title>{S.title}</title>
            </Head>
            <Component {...pageProps} />
        </>
    );
}

export default MyApp;
