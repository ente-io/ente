import React from 'react';
import Document, { Html, Head, Main, NextScript } from 'next/document';
import { ServerStyleSheet } from 'styled-components';

export default class MyDocument extends Document {
    static async getInitialProps(ctx) {
        const sheet = new ServerStyleSheet();
        const originalRenderPage = ctx.renderPage;

        try {
            ctx.renderPage = () =>
                originalRenderPage({
                    enhanceApp: (App) => (props) =>
                        sheet.collectStyles(<App {...props} />),
                });

            const initialProps = await Document.getInitialProps(ctx);
            return {
                ...initialProps,
                styles: (
                    <>
                        {initialProps.styles}
                        {sheet.getStyleElement()}
                    </>
                ),
            };
        } finally {
            sheet.seal();
        }
    }

    render() {
        return (
            <Html lang="en">
                <Head>
                    <meta
                        name="description"
                        content="ente is a privacy focussed photo storage service that offers end-to-end encryption."
                    />
                    <link
                        rel="icon"
                        href="/images/favicon.png"
                        type="image/png"
                    />
                    <link rel="manifest" href="manifest.json" />
                    <link rel="apple-touch-icon" href="/images/ente-512.png" />
                    <meta name="theme-color" content="#111" />
                    <link
                        rel="icon"
                        type="image/png"
                        href="/images/favicon.png"
                    />
                    <meta name="apple-mobile-web-app-capable" content="yes" />
                    <meta
                        name="apple-mobile-web-app-status-bar-style"
                        content="black"
                    />
                    <meta
                        httpEquiv="Cross-Origin-Opener-Policy"
                        content="same-origin"
                    />
                    <meta
                        httpEquiv="Cross-Origin-Embedder-Policy"
                        content="require-corp"
                    />
                </Head>
                <body>
                    <Main />
                    <NextScript />
                </body>
            </Html>
        );
    }
}
