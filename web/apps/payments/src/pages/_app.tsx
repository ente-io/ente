import "bootstrap/dist/css/bootstrap.min.css";
import type { AppProps } from "next/app";
import Head from "next/head";
import constants from "utils/strings";
import "../styles/globals.css";

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
