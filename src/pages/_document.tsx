import React from 'react';
import Document, { Html, Head, Main, NextScript } from 'next/document';
import { ServerStyleSheet } from 'styled-components';
import crypto from 'crypto';

const cspHashOf = (text) => {
    const hash = crypto.createHash('sha256');
    hash.update(text);
    return `'sha256-${hash.digest('base64')}'`;
};

const convertToCSPString = (csp) => {
    let cspStr = '';
    for (const k in csp) {
        if (Object.prototype.hasOwnProperty.call(csp, k)) {
            cspStr += `${k} ${csp[k]}; `;
        }
    }
    return cspStr;
};

const BASE_CSP_DIRECTIVES = {
    'default-src': "'none'",
    'report-uri': 'https://csp-reporter.ente.workers.dev',
    'report-to': 'https://csp-reporter.ente.workers.dev',
    'style-src': "'self'",
    'font-src': "'self'",
};

const DEV_CSP_DIRECTIVES = {
    'default-src': "'self'",
    'style-src': "'self' 'unsafe-inline'",
    'font-src': "'self' data:",
};

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
        let csp = {
            ...BASE_CSP_DIRECTIVES,
            'script-src': `'self' ${cspHashOf(
                NextScript.getInlineScriptSource(this.props)
            )}`,
        };
        if (process.env.NODE_ENV !== 'production') {
            csp = {
                ...BASE_CSP_DIRECTIVES,
                ...DEV_CSP_DIRECTIVES,
                'script-src': `'unsafe-eval' 'self'  ${cspHashOf(
                    NextScript.getInlineScriptSource(this.props)
                )}`,
            };
        }
        return (
            <Html lang="en">
                <Head>
                    <meta
                        httpEquiv="Content-Security-Policy"
                        content={convertToCSPString(csp)}
                    />
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
                </Head>
                <body>
                    <Main />
                    <NextScript />
                </body>
            </Html>
        );
    }
}
